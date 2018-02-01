#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author: Furushchev <furushchev@jsk.imi.i.u-tokyo.ac.jp>

from pathlib2 import Path
import pymongo
import re
import subprocess as sp
import time
from tqdm import tqdm
import sys


def dump(addr, port, out, db=None, col=None):
    Path(out).mkdir(parents=True, exist_ok=True)
    regex = re.compile(r"^([0-9]+/[0-9]+)$")

    cmd = ['mongodump', '--verbose', '--out', out, "--host", addr, "--port", str(port)]
    if db:
        cmd += ['--db', db]
    if col:
        cmd += ['--collection', col]

    p = sp.Popen(cmd, stdout=sp.PIPE)
    with tqdm(total=100) as bar:
        prev_perc = 0
        while p.poll() is None:
            progress = p.stdout.readline().split()
            progress = filter(regex.match, progress)
            if progress:
                cur, total = progress[0].split('/')
                perc = int(float(cur) / float(total) * 100)
                diff = perc - prev_perc
                if diff > 0:
                    bar.update(perc - prev_perc)
                prev_perc = perc
            time.sleep(0.1)

    print "mongodump exited with code %d" % p.poll()
    return p.poll() == 0


def restore(dump_path, db=None, col=None):
    if not Path(dump_path).exists():
        raise OSError("dump path %s not found" % dump_path)

    regex = re.compile(r"^([0-9]+/[0-9]+)$")

    cmd = ["mongorestore", "--verbose"]
    if db:
        cmd += ['--db', db]
    if col:
        cmd += ['--collection', col]

    cmd += [dump_path]

    p = sp.Popen(cmd, stdout=sp.PIPE)
    with tqdm(total=100) as bar:
        prev_perc = 0
        while p.poll() is None:
            progress = p.stdout.readline().split()
            progress = filter(regex.match, progress)
            if progress:
                cur, total = progress[0].split('/')
                perc = int(float(cur) / float(total) * 100)
                diff = perc - prev_perc
                if diff > 0:
                    bar.update(perc - prev_perc)
                prev_perc = perc
            time.sleep(0.1)

    print "mongorestore exited with code %d" % p.poll()
    return p.poll() == 0


if __name__ == '__main__':
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("--host", help="hostname", default="133.11.216.217")
    p.add_argument("--port", help="port number",
                   type=int, default=27017)

    p.add_argument("--db", "-d", default=None,
                   help="Database to be backed up")
    p.add_argument("--col", "-c", default=None,
                   help="Collection to be backed up")

    p.add_argument("--path", "-p", default="/tmp/replicate",
                   help="Dump path")
    p.add_argument("--rm", action="store_true")

    args = p.parse_args()

    if not dump(args.host, args.port, args.path,
                args.db, args.col):
        exit(1)
    elif not restore(args.path, args.db, args.col):
        exit(1)

    if args.rm and Path(args.path).exists():
        import shutil
        try:
            shutil.rmtree(args.path)
        except Exception as e:
            print "Failed to dump path %s: %s" % (args.path, str(e))

    exit(0)
