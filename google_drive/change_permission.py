#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Author: furushchev <furushchev@jsk.imi.i.u-tokyo.ac.jp>


import httplib2
import os

try:
    import apiclient
    import oauth2client.client
    import oauth2client.file
except:
    print "run 'sudo pip install --upgrade google-api-python-client'"
    exit(1)

try:
    input = raw_input
except:
    pass


def get_drive_service(credential_path=None):
    try:
        storage = oauth2client.file.Storage(credential_path)
        credentials = storage.get()
        assert credentials
    except:
        flow = oauth2client.client.OAuth2WebServerFlow(
            client_id="665081966568.apps.googleusercontent.com",
            client_secret="ckGVrYYQ_GE7O4rL80ozlEXR",
            scope="https://www.googleapis.com/auth/drive",
            redirect_uri=oauth2client.client.OOB_CALLBACK_URN)
        authorize_url = flow.step1_get_authorize_url()
        print "Click to authorize: %s" % authorize_url

        code = str()
        while not code:
            code = input("Verification code?: ")

        credentials = flow.step2_exchange(code)
        if credential_path is not None:
            storage = oauth2client.file.Storage(credential_path)
            storage.put(credentials)

    http = credentials.authorize(httplib2.Http())
    return apiclient.discovery.build('drive', 'v3', http=http)


def _get_children_folders(service, folder_id, depth, max_depth):
    if max_depth >= 0 and depth > max_depth:
        return
    page_token = None
    yield folder_id
    queries = ["'%s' in parents" % folder_id,
               "trashed=false",
               "mimeType='application/vnd.google-apps.folder'"]
    while True:
        res = service.files().list(
            q=" and ".join(queries),
            spaces="drive",
            fields="nextPageToken, files(id)",
            pageToken=page_token).execute()
        for e in res.get("files", list()):
            for fid in _get_children_folders(service, e.get("id"), depth+1, max_depth):
                yield fid
        if page_token is None:
            break


def get_children_folders(service, folder_id, max_depth):
    for fid in _get_children_folders(service, folder_id, 0, max_depth):
        yield fid


def get_children_files(service, folder_id):
    page_token = None
    files = list()
    queries = ["'%s' in parents" % folder_id,
               "trashed=false",
               "mimeType!='application/vnd.google-apps.folder'"]
    while True:
        res = service.files().list(
            q=" and ".join(queries),
            spaces="drive",
            fields="nextPageToken, files(id)",
            pageToken=page_token).execute()
        for f in res.get("files"):
            yield f.get("id")
        if page_token is None:
            break



def get_file_id(service, name, folder_only=False, file_only=False):
    page_token = None
    folders = dict()
    queries = ["name='%s'" % name,
               "trashed=false"]
    if folder_only:
        queries += ["mimeType='application/vnd.google-apps.folder'"]
    elif file_only:
        queries += ["mimeType!='application/vnd.google-apps.folder'"]
    q = " and ".join(queries)
    while True:
        res = service.files().list(
            q=" and ".join(queries),
            spaces="drive",
            fields="nextPageToken, files(id, name, webViewLink)",
            pageToken=page_token).execute()
        for e in res.get("files", list()):
            try:
                folders[e.get("id")] = e.get("webViewLink")
            except:
                pass
        if page_token is None:
            break
    if len(folders) > 1:
        print "Found %d directories with the same name" % len(folders)
        folders = [f for f in folders.items()]
        for i, f in enumerate(folders):
            print "#%d: %s (%s)" % (i, f[0], f[1])
        while True:
            cid = input("Choose number: ")
            try:
                cid = int(cid)
                if 0 <= cid < len(folders):
                    return folders[cid][0]
            except:
                print "Invalid input"
                continue
    elif len(folders) == 1:
        return folders.keys()[0]
    else:
        return None


def get_permissions(service, file_id):
    res = service.permissions().list(
        fileId=file_id).execute()
    return res.get("permissions")


def revoke_permission(service, file_id):
    permissions = get_permissions(service, file_id)
    for p in permissions:
        if p.get("type") == "domain":
            pid = p.get("id")
            service.permissions().delete(
                fileId=file_id,
                permissionId=pid).execute()
            print "revoked: %s" % p.get("id")


def main():
    import argparse
    import pprint
    p = argparse.ArgumentParser(description="Revoke domain permissions")
    p.add_argument("folder", help="folder name from which starts permission change")
    p.add_argument("--credentials", "-c",
                   help="path to credential file",
                   default="credentials")
    p.add_argument("--depth", "-d", help="max depth for searching",
                   default=-1)
    args = p.parse_args()

    service = get_drive_service(args.credentials)

    folder_id = get_file_id(service, args.folder)
    print "selected folder id: %s" % folder_id

    for i, foid in enumerate(get_children_folders(service, folder_id, max_depth=args.depth)):
        revoke_permission(service, foid)
        for fiid in get_children_files(service, foid):
            revoke_permission(service, fiid)

    print "Done!"


if __name__ == '__main__':
    main()
