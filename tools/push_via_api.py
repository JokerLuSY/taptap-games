# -*- coding: utf-8 -*-
"""通过 GitHub Git Data API 推送当前 HEAD (绕过 git 协议超时)"""
import base64
import json
import os
import subprocess
import time
import urllib.request
import urllib.error

TOKEN = os.environ["GH_TOKEN"]
REPO = "JokerLuSY/taptap-games"
API = "https://api.github.com"


def api(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + TOKEN)
    req.add_header("User-Agent", "cursor-agent")
    req.add_header("Accept", "application/vnd.github+json")
    if data:
        req.add_header("Content-Type", "application/json")
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 409 and attempt < 5:
                print("409 conflict, retry in 15s (%d/5)" % (attempt + 1), flush=True)
                time.sleep(15)
                continue
            raise


def git(*args):
    return subprocess.run(["git", *args], capture_output=True).stdout.decode()


def main():
    tree_entries = []
    listing = git("ls-tree", "-r", "HEAD")
    for line in listing.strip().splitlines():
        mode, typ, sha, path = line.split(maxsplit=3)
        if typ == "blob":
            tree_entries.append({"path": path, "mode": mode, "type": "blob", "sha": sha})
    print("entries:", len(tree_entries), flush=True)

    # 缺失的 blob 逐个上传
    missing = []
    for i in range(0, len(tree_entries), 100):
        chunk = tree_entries[i:i + 100]
        # 探测: 逐个 HEAD 检查成本高, 直接尝试创建(已存在的会直接返回)
        for e in chunk:
            pass
    uploaded = 0
    for e in tree_entries:
        try:
            api("GET", "/repos/%s/git/blobs/%s" % (REPO, e["sha"]))
            continue
        except Exception:
            pass
        content = subprocess.run(["git", "cat-file", "blob", e["sha"]], capture_output=True).stdout
        api("POST", "/repos/%s/git/blobs" % REPO, {
            "content": base64.b64encode(content).decode(),
            "encoding": "base64",
        })
        uploaded += 1
        if uploaded % 10 == 0:
            print("uploaded blobs:", uploaded, flush=True)
    print("blobs uploaded:", uploaded, flush=True)

    tree = api("POST", "/repos/%s/git/trees" % REPO, {"tree": tree_entries})
    print("tree:", tree["sha"], flush=True)
    commit_sha = git("rev-parse", "HEAD").strip()
    msg = git("log", "-1", "--format=%B").strip()
    commit = api("POST", "/repos/%s/git/commits" % REPO, {
        "message": msg,
        "tree": tree["sha"],
        "parents": [],
    })
    print("commit:", commit["sha"], flush=True)
    ref = api("POST", "/repos/%s/git/refs" % REPO, {
        "ref": "refs/heads/main",
        "sha": commit["sha"],
    })
    print("ref pushed:", ref["ref"], flush=True)


if __name__ == "__main__":
    main()
