#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author: Yuki Furuta <furushchev@jsk.imi.i.u-tokyo.ac.jp>


from __future__ import print_function
import click
from splinter import Browser
from six.moves import urllib
import selenium.common.exceptions

@click.command()
@click.argument('username')
@click.argument('password')
def main(username, password):
    try:
        browser = Browser('firefox')
    except selenium.common.exceptions.WebDriverException:
        import os
        binpath = os.path.expanduser('~/.local/bin/geckodriver')
        tarpath = '/tmp/geckodriver.tar.gz'
        os.environ['PATH'] = os.path.dirname(binpath) + ':' + os.environ['PATH']
        if not os.path.exists(binpath):
            from six.moves import urllib
            from tarfile import TarFile
            import shutil
            if not os.path.exists(tarpath):
                urllib.request.urlretrieve(
                    'https://github.com/mozilla/geckodriver/releases/download/v0.24.0/geckodriver-v0.24.0-linux64.tar.gz',
                    tarpath)
            with TarFile.open(tarpath) as f:
                f.extractall()
            try:
                os.makedirs(os.path.dirname(binpath))
            except OSError:
                pass
            shutil.move('geckodriver', binpath)

    browser = Browser(
        'firefox',
        headless=True,
        user_agent='SoftBank/2.0/004SH/SHJ001/SN 12345678901 Browser/NetFront/3.5 Profile/MIDP-2.0 Configuration/CLDC-1.1')
    browser.visit('http://furushchev.ru')
    if browser.is_element_not_present_by_name('login', wait_time=10):
        print('Failed to login or you are already logged in')
    else:
        browser.fill('SWUserName', username)
        browser.fill('SWPassword', password)
        browser.find_by_name('login').click()
        print('Successfully logged in!')


if __name__ == '__main__':
    main()
