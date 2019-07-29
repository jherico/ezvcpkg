import os
import platform
import time

try:
    import fcntl
except ImportError:
    fcntl = None

try:
    import msvcrt
except ImportError:
    msvcrt = None

# Used to ensure only one instance of the script runs at a time
class Singleton:
    def __init__(self, path):
        self.fh = None
        self.windows = 'Windows' == platform.system()
        self.path = path

    def __enter__(self):
        success = False
        while not success:
            try:
                if self.windows:
                    if os.path.exists(self.path):
                        os.unlink(self.path)
                    self.fh = os.open(self.path, os.O_CREAT | os.O_EXCL | os.O_RDWR)
                else:
                    self.fh = open(self.path, 'x')
                    fcntl.lockf(self.fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
                success = True
            except EnvironmentError:
                if self.fh is not None:
                    if self.windows:
                        os.close(self.fh)
                    else:
                        self.fh.close()
                    self.fh = None
                # print is horked here so write directly to stdout.
                with open(1, mode="w", closefd=False) as _stdout:
                    _stdout.write("Couldn't aquire lock, retrying in 10 seconds\n")
                    _stdout.flush()
                time.sleep(10)
        return self

    def __exit__(self, type, value, traceback):
        if self.windows:
            os.close(self.fh)
        else:
            fcntl.lockf(self.fh, fcntl.LOCK_UN)
            self.fh.close()
        os.unlink(self.path)

