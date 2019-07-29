#!python

import logging

import ezvcpkg_singleton
import ezvcpkg_vcpkg

import argparse
import os
import platform
import shutil
import sys
import time

from contextlib import contextmanager

logging.basicConfig(datefmt='%H:%M:%S', format='%(asctime)s %(message)s', level=logging.INFO)
logger = logging.getLogger('ezvcpkg')

@contextmanager
def timer(name):
    ''' Print the elapsed time a context's execution takes to execute '''
    start = time.time()
    yield
    # Please take care when modifiying this print statement.
    # Log parsing logic may depend on it.
    logger.info('%s took %.3f secs' % (name, time.time() - start))

def parse_args():
    # our custom ports, relative to the script location
    from argparse import ArgumentParser
    parser = ArgumentParser(description='Prepare build dependencies.')
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--force-bootstrap', action='store_true')
    parser.add_argument('--force-build', action='store_true')
    parser.add_argument('--vcpkg-commit', required=True, type=str, help='The commit ID of the vcpkg repository to use')
    parser.add_argument('--vcpkg-url', required=True, type=str, help='The vcpkg Git repository to use')
    parser.add_argument('--vcpkg-root', type=str, help='The location of the vcpkg distribution')
    parser.add_argument('--vcpkg-packages', nargs='+', required=True, help='Packages')
    parser.add_argument('--build-root', required=True, type=str, help='The location of the cmake build')
    if True:
        args = parser.parse_args()
    else:
        args = parser.parse_args([
            '--build-root', 'C:/git/amuck/build', 
            '--vcpkg-url', 'https://github.com/microsoft/vcpkg.git', 
            '--vcpkg-commit', 'f990dfaa5ba82155f95b75021453c075816fd4be',
            '--vcpkg-root', 'E:/vcpkg/test',
            '--vcpkg-package', 'glm', 'vulkan', 'basisu'
            ])
    return args

def main():
    args = parse_args()
    logger.info('start')
    # Only allow one instance of the program to run at a time
    pm = ezvcpkg_vcpkg.VcpkgRepo(args)
    with ezvcpkg_singleton.Singleton(pm.lockFile):
        with timer('Bootstraping'):
            if not pm.upToDate():
                pm.bootstrap()
        # Always write the tag, even if we changed nothing.  This 
        # allows vcpkg to reclaim disk space by identifying directories with
        # tags that haven't been touched in a long time
        pm.writeTag()
        # Grab our required dependencies:
        #  * build host tools, like spirv-cross and scribe
        #  * build client dependencies like openssl and nvtt
        with timer('Setting up dependencies'):
            pm.setupDependencies()
        # wipe out the build directories (after writing the tag, since failure 
        # here shouldn't invalidte the vcpkg install)
        with timer('Cleaning out of date builds'):
            pm.cleanBuilds()
        # Write the vcpkg config to the build directory last
        with timer('Writing CMake configuration'):
            pm.writeConfig()
    logger.info('end')

logger.debug(sys.argv)
main()
