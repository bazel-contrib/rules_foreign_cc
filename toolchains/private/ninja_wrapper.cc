#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <process.h>
#define real_execv _execv
#else
#include <unistd.h>
#define real_execv execv
#endif

using namespace std;

const char *getvar(const char *name) {
    const char *val = getenv(name);
    if (!val) {
        cerr << name << " must be set" << endl;
        exit(42);
    }
    return val;
}

int main(int argc, char *argv[]) {
    vector<char *> args(argv, argv + argc);
    // we need this null at the end so when we pass the raw underlying data to
    // execv, it sees a \0\0 terminator.
    args.push_back(NULL);

    const char *root = getvar("EXT_BUILD_ROOT");
    const char *ninja = getvar("REAL_NINJA");

    auto ninja_path = filesystem::path(root) / ninja;
    if (!filesystem::exists(ninja_path)) {
        cerr << "ninja path does not exist: " << ninja_path << endl;
        exit(42);
    }

    // this will leak if we don't exec properly, but we also exit immediately in
    // that case, so...
    args[0] = strdup(ninja_path.string().c_str());

    if (const char *jobs_p = getenv("NINJA_JOBS")) {
        errno = 0;
        long ninja_jobs = strtol(jobs_p, NULL, 10);
        if (errno) {
            cerr << "failed to convert NINJA_JOBS to an integer: "
                 << strerror(errno) << endl;
            exit(42);
        }

        if (ninja_jobs < 0) {
            cerr << "NINJA_JOBS must be >= 0" << endl;
            exit(42);
        }

        stringstream ss;
        ss << "-j" << ninja_jobs;

        // leaks here, too
        // we want the -j option to be _after_ the program name (which is in
        // arg0) but _before_ anything else, so it can be overridden by a later
        // flag
        args.insert(args.begin() + 1, strdup(ss.str().c_str()));
    }

    int ret = real_execv(args[0], const_cast<char *const *>(args.data()));
    if (ret < 0) {
        cerr << "failed to execv: " << strerror(errno) << endl;
    }
    // shouldn't hit this unless something is wrong, so...
    return 42;
}
