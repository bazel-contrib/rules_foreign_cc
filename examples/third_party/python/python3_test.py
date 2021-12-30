
import sys
import platform

if __name__ == "__main__":

    assert('python3_test.runfiles/python3/python3/bin/' in sys.executable)
    assert(platform.python_version() == "3.10.1")
