#define _GNU_SOURCE

#include <archive.h>
#include <archive_entry.h>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#elif defined(__APPLE__)
#include <dlfcn.h>
#include <mach-o/dyld.h>
#else
#include <dlfcn.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char* kPayload = "rules_foreign_cc_transitive_test";
static const char* kExpected =
    "expected libarchive+zlib loaded: payload=rules_foreign_cc_transitive_test";

static void fail_archive(const char* operation, struct archive* archive) {
    const char* error = archive_error_string(archive);
    fprintf(stderr, "%s failed: %s\n", operation,
            error ? error : "unknown error");
    exit(1);
}

static void fail_message(const char* message) {
    fprintf(stderr, "%s\n", message);
    exit(1);
}

#ifdef _WIN32
static const char* kLibarchiveModuleNames[] = {
    "archive.dll",
    "libarchive.dll",
    NULL,
};

static const char* kZlibModuleNames[] = {
    "zlib1.dll",
    "libz.dll",
    "z.dll",
    NULL,
};

static const void* find_loaded_symbol(const char* const* module_names,
                                      const char* symbol_name) {
    const char* const* module_name;

    for (module_name = module_names; *module_name != NULL; ++module_name) {
        HMODULE module = GetModuleHandleA(*module_name);
        FARPROC symbol;

        if (module == NULL) {
            continue;
        }

        symbol = GetProcAddress(module, symbol_name);
        if (symbol != NULL) {
            return (const void*)symbol;
        }
    }
    return NULL;
}
#endif

static void print_loaded_path(const char* name, const void* symbol) {
#ifdef _WIN32
    HMODULE module = NULL;
    char path[MAX_PATH];
    DWORD length;

    if (symbol != NULL &&
        GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                               GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                           (LPCSTR)symbol, &module)) {
        length = GetModuleFileNameA(module, path, sizeof(path));
        if (length > 0 && length < sizeof(path)) {
            printf("loaded %s: %s\n", name, path);
            return;
        }
    }
    printf("loaded %s: <unresolved>\n", name);
#else
    Dl_info info;

    if (symbol != NULL && dladdr(symbol, &info) != 0 &&
        info.dli_fname != NULL) {
        printf("loaded %s: %s\n", name, info.dli_fname);
        return;
    }
    printf("loaded %s: <unresolved>\n", name);
#endif
}

#ifdef __APPLE__
static int starts_with(const char* text, const char* prefix) {
    return strncmp(text, prefix, strlen(prefix)) == 0;
}

static int ends_with(const char* text, const char* suffix) {
    size_t text_length = strlen(text);
    size_t suffix_length = strlen(suffix);

    return text_length >= suffix_length &&
           strcmp(text + text_length - suffix_length, suffix) == 0;
}

static int is_system_library_path(const char* path) {
    return starts_with(path, "/usr/lib/") ||
           starts_with(path, "/System/Library/");
}

static int is_zlib_image_path(const char* path) {
    const char* basename = strrchr(path, '/');

    basename = basename != NULL ? basename + 1 : path;
    return strcmp(basename, "libz.dylib") == 0 ||
           (starts_with(basename, "libz.") && ends_with(basename, ".dylib"));
}

static const char* find_loaded_zlib_image_path(int prefer_non_system) {
    uint32_t image_count = _dyld_image_count();
    uint32_t index;

    for (index = 0; index < image_count; ++index) {
        const char* path = _dyld_get_image_name(index);

        if (path == NULL || !is_zlib_image_path(path)) {
            continue;
        }
        if (prefer_non_system && is_system_library_path(path)) {
            continue;
        }
        return path;
    }
    return NULL;
}

static void print_loaded_zlib_path(void) {
    const char* path = find_loaded_zlib_image_path(1);

    if (path == NULL) {
        path = find_loaded_zlib_image_path(0);
    }
    if (path != NULL) {
        printf("loaded zlib: %s\n", path);
        return;
    }
    print_loaded_path("zlib", NULL);
}
#endif

static void print_loaded_symbol_path(const char* name,
                                     const void* fallback_symbol,
                                     const char* symbol_name
#ifdef _WIN32
                                     ,
                                     const char* const* module_names
#endif
) {
#ifdef _WIN32
    const void* symbol = find_loaded_symbol(module_names, symbol_name);
    print_loaded_path(name, symbol != NULL ? symbol : fallback_symbol);
#else
    (void)symbol_name;
    print_loaded_path(name, fallback_symbol);
#endif
}

static void print_optional_loaded_symbol_path(const char* name,
                                              const char* symbol_name) {
#ifdef _WIN32
    const void* symbol;

    if (strcmp(name, "zlib") == 0) {
        symbol = find_loaded_symbol(kZlibModuleNames, symbol_name);
        print_loaded_path(name, symbol);
        return;
    }
    print_loaded_path(name, NULL);
#elif defined(__APPLE__)
    if (strcmp(name, "zlib") == 0) {
        (void)symbol_name;
        print_loaded_zlib_path();
        return;
    }
    print_loaded_path(name, NULL);
#else
    print_loaded_path(name, dlsym(RTLD_DEFAULT, symbol_name));
#endif
}

static size_t write_archive(char* buffer, size_t buffer_size) {
    struct archive* archive = archive_write_new();
    struct archive_entry* entry = archive_entry_new();
    size_t used = 0;

    if (archive == NULL || entry == NULL) {
        fail_message("failed to allocate libarchive writer");
    }
    if (archive_write_add_filter_gzip(archive) != ARCHIVE_OK) {
        fail_archive("archive_write_add_filter_gzip", archive);
    }
    if (archive_write_set_format_pax_restricted(archive) != ARCHIVE_OK) {
        fail_archive("archive_write_set_format_pax_restricted", archive);
    }
    if (archive_write_open_memory(archive, buffer, buffer_size, &used) !=
        ARCHIVE_OK) {
        fail_archive("archive_write_open_memory", archive);
    }

    archive_entry_set_pathname(entry, "payload.txt");
    archive_entry_set_size(entry, (la_int64_t)strlen(kPayload));
    archive_entry_set_filetype(entry, AE_IFREG);
    archive_entry_set_perm(entry, 0644);

    if (archive_write_header(archive, entry) != ARCHIVE_OK) {
        fail_archive("archive_write_header", archive);
    }
    if (archive_write_data(archive, kPayload, strlen(kPayload)) < 0) {
        fail_archive("archive_write_data", archive);
    }
    archive_entry_free(entry);

    if (archive_write_close(archive) != ARCHIVE_OK) {
        fail_archive("archive_write_close", archive);
    }
    if (archive_write_free(archive) != ARCHIVE_OK) {
        fail_message("archive_write_free failed");
    }
    return used;
}

static void read_archive(const char* buffer, size_t used) {
    struct archive* archive = archive_read_new();
    struct archive_entry* entry = NULL;
    char payload[128] = {0};
    la_ssize_t read_bytes;

    if (archive == NULL) {
        fail_message("failed to allocate libarchive reader");
    }
    if (archive_read_support_filter_gzip(archive) != ARCHIVE_OK) {
        fail_archive("archive_read_support_filter_gzip", archive);
    }
    if (archive_read_support_format_tar(archive) != ARCHIVE_OK) {
        fail_archive("archive_read_support_format_tar", archive);
    }
    if (archive_read_open_memory(archive, buffer, used) != ARCHIVE_OK) {
        fail_archive("archive_read_open_memory", archive);
    }
    if (archive_read_next_header(archive, &entry) != ARCHIVE_OK) {
        fail_archive("archive_read_next_header", archive);
    }
    if (strcmp(archive_entry_pathname(entry), "payload.txt") != 0) {
        fail_message("unexpected archive entry path");
    }

    read_bytes = archive_read_data(archive, payload, sizeof(payload) - 1);
    if (read_bytes < 0) {
        fail_archive("archive_read_data", archive);
    }
    payload[read_bytes] = '\0';
    if (strcmp(payload, kPayload) != 0) {
        fail_message("unexpected archive payload");
    }

    if (archive_read_close(archive) != ARCHIVE_OK) {
        fail_archive("archive_read_close", archive);
    }
    if (archive_read_free(archive) != ARCHIVE_OK) {
        fail_message("archive_read_free failed");
    }
}

int main(void) {
    char buffer[8192];
    size_t used = write_archive(buffer, sizeof(buffer));
    read_archive(buffer, used);
    puts(kExpected);
    print_loaded_symbol_path("libarchive", (const void*)&archive_read_new,
                             "archive_read_new"
#ifdef _WIN32
                             ,
                             kLibarchiveModuleNames
#endif
    );
    print_optional_loaded_symbol_path("zlib", "zlibVersion");
    return 0;
}
