// This is a thin(-ish) wrapper around ninja whose only purposes is to convert
// environment variables (namely: NINJA_JOBS) into the correct -j argument. This
// is necessary because the ninja project does not like environment variables
// (https://github.com/ninja-build/ninja/issues/1482)
//
// This is in c++ instead of python or shell because both of those languages
// rely on a shim runner on windows, and the shim runner depends on runfiles or
// the manifest system, which means it doesn't work if you change the working
// directory, which most callers of this wrapper will have done.
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <unistd.h>
#endif

#define WRAPPER_ERROR 42

using namespace std;

const char *getvar(const char *name) {
    const char *val = getenv(name);
    if (!val) {
        cerr << name << " must be set" << endl;
        exit(WRAPPER_ERROR);
    }
    return val;
}

string JoinPath(const string &root, const string &path) {
#ifdef _WIN32
    const char separator = '\\';
#else
    const char separator = '/';
#endif
    return root + separator + path;
}

bool IsAbsolutePath(const string &path) {
    if (path.empty()) {
        return false;
    }
#ifdef _WIN32
    // Drive-letter path, e.g. C:\foo
    if (path.size() > 2 &&
        ((path[0] >= 'A' && path[0] <= 'Z') ||
         (path[0] >= 'a' && path[0] <= 'z')) &&
        path[1] == ':' && (path[2] == '\\' || path[2] == '/')) {
        return true;
    }
    // UNC path, e.g. \\server\share
    if (path.size() > 1 && path[0] == '\\' && path[1] == '\\') {
        return true;
    }
    return false;
#else
    return path[0] == '/';
#endif
}

bool IsNinjaFromPath() {
    const char *ninja_from_path = getenv("NINJA_FROM_PATH");
    return ninja_from_path && strcmp(ninja_from_path, "1") == 0;
}

bool ParseNinjaJobs(const char *jobs_p, long *jobs_out) {
    errno = 0;
    char *end = nullptr;
    long parsed = strtol(jobs_p, &end, 10);
    if (errno || end == jobs_p || *end != '\0') {
        return false;
    }
    *jobs_out = parsed;
    return true;
}

#ifdef _WIN32
string QuoteWindowsArg(const string &arg) {
    if (arg.find_first_of(" \t\n\v\"") == string::npos) {
        return arg;
    }

    string result = "\"";
    size_t backslashes = 0;
    for (char c : arg) {
        if (c == '\\') {
            ++backslashes;
        } else if (c == '"') {
            result.append(backslashes * 2 + 1, '\\');
            result.push_back('"');
            backslashes = 0;
        } else {
            result.append(backslashes, '\\');
            backslashes = 0;
            result.push_back(c);
        }
    }
    result.append(backslashes * 2, '\\');
    result.push_back('"');
    return result;
}

string GetWindowsErrorMessage(DWORD code) {
    LPSTR buffer = nullptr;
    DWORD size = FormatMessageA(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        nullptr, code, 0, reinterpret_cast<LPSTR>(&buffer), 0, nullptr);
    string message;
    if (size && buffer) {
        message.assign(buffer, size);
        LocalFree(buffer);
    } else {
        message = "unknown error";
    }
    return message;
}

int RunProcessWindows(const string &program, const vector<string> &args,
                      bool search_path) {
    string command_line;
    for (size_t i = 0; i < args.size(); ++i) {
        if (i > 0) {
            command_line.push_back(' ');
        }
        command_line += QuoteWindowsArg(args[i]);
    }

    STARTUPINFOA startup_info = {};
    startup_info.cb = sizeof(startup_info);
    PROCESS_INFORMATION process_info = {};

    vector<char> mutable_command_line(command_line.begin(), command_line.end());
    mutable_command_line.push_back('\0');

    LPCSTR application_name = search_path ? nullptr : program.c_str();
    BOOL ok = CreateProcessA(application_name, mutable_command_line.data(),
                             nullptr, nullptr, TRUE, 0, nullptr, nullptr,
                             &startup_info, &process_info);
    if (!ok) {
        DWORD err = GetLastError();
        cerr << "failed to CreateProcess: " << GetWindowsErrorMessage(err)
             << endl;
        return WRAPPER_ERROR;
    }

    DWORD wait_result = WaitForSingleObject(process_info.hProcess, INFINITE);
    if (wait_result != WAIT_OBJECT_0) {
        DWORD err = GetLastError();
        cerr << "failed to wait for process: " << GetWindowsErrorMessage(err)
             << endl;
        CloseHandle(process_info.hThread);
        CloseHandle(process_info.hProcess);
        return WRAPPER_ERROR;
    }

    DWORD exit_code = 0;
    if (!GetExitCodeProcess(process_info.hProcess, &exit_code)) {
        DWORD err = GetLastError();
        cerr << "failed to read process exit code: "
             << GetWindowsErrorMessage(err) << endl;
        CloseHandle(process_info.hThread);
        CloseHandle(process_info.hProcess);
        return WRAPPER_ERROR;
    }

    CloseHandle(process_info.hThread);
    CloseHandle(process_info.hProcess);
    return static_cast<int>(exit_code);
}
#endif

int main(int argc, char *argv[]) {
    vector<string> args;
    args.reserve(static_cast<size_t>(argc));
    for (int i = 0; i < argc; ++i) {
        args.push_back(argv[i]);
    }

    const string root = getvar("EXT_BUILD_ROOT");
    const string ninja = getvar("REAL_NINJA");

    const bool ninja_from_path = IsNinjaFromPath();
    string ninja_path = ninja;
    if (!ninja_from_path && !IsAbsolutePath(ninja)) {
        // can't rely on std::filesystem existing.
        ninja_path = JoinPath(root, ninja);
    }
    args[0] = ninja_path;

    if (const char *jobs_p = getenv("NINJA_JOBS")) {
        long ninja_jobs = 0;
        if (!ParseNinjaJobs(jobs_p, &ninja_jobs)) {
            cerr << "failed to convert NINJA_JOBS to an integer: " << jobs_p
                 << endl;
            exit(WRAPPER_ERROR);
        }

        if (ninja_jobs < 0) {
            cerr << "NINJA_JOBS must be >= 0" << endl;
            exit(WRAPPER_ERROR);
        }

        // we want the -j option to be _after_ the program name (which is in
        // arg0) but _before_ anything else, so it can be overridden by a later
        // flag
        args.insert(args.begin() + 1, "-j" + to_string(ninja_jobs));
    }

#ifdef _WIN32
    return RunProcessWindows(ninja_path, args, ninja_from_path);
#else
    vector<const char *> exec_args;
    exec_args.reserve(args.size() + 1);
    for (string &arg : args) {
        exec_args.push_back(arg.c_str());
    }
    exec_args.push_back(nullptr);

    int ret = 0;
    if (ninja_from_path) {
        ret = execvp(exec_args[0], const_cast<char *const *>(exec_args.data()));
    } else {
        ret = execv(exec_args[0], const_cast<char *const *>(exec_args.data()));
    }
    if (ret < 0) {
        cerr << "failed to exec: " << strerror(errno) << endl;
    }
    // shouldn't hit this unless something is wrong, so...
    return WRAPPER_ERROR;
#endif
}
