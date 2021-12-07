
import sys
import platform

if __name__ == "__main__":

    assert('python2_test.runfiles/python2/python2/bin/' in sys.executable)
    assert(platform.python_version() == "2.7.18")
