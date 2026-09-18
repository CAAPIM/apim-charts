# Copyright (c) 2026 Broadcom Inc. and its subsidiaries. All Rights Reserved.
# //AI assistance has been used to generate some or all contents of this file. That includes, but is not limited to, new code, modifying existing code, stylistic edits.
import argparse
import os
import sys
import requests
import subprocess
import tempfile
from pathlib import Path
from ruamel.yaml import YAML

TARGET_CHART = "portal"
ALLOWED_VERSIONS = [
    "2.3.15-patch.2",
    "2.3.15-patch.1"
    
]

parser = argparse.ArgumentParser(description='Push apim portal helm charts to artifactory')
parser.add_argument('--index', default='index.yaml', help='index file to read for chart releases')
parser.add_argument('--release', action='store_true', help='flag to push to release repo instead of dev')
parser.add_argument('--chart', default=TARGET_CHART, help='specific chart name to push (default: portal)')
parser.add_argument('--version', default=None, help='optional specific chart version to push')

args = parser.parse_args()
username = os.getenv('ARTIFACTORY_CREDS_USR')
password = os.getenv('ARTIFACTORY_CREDS_PSW')
token = os.getenv('GITHUB_TOKEN')

if not username or not password or not token:
    sys.exit("please set env for ARTIFACTORY_CREDS_USR, ARTIFACTORY_CREDS_PSW, and GITHUB_TOKEN")

helm_stage = "release" if args.release else "dev"
helm_repo = f"apim-docker-{helm_stage}-local.usw1.packages.broadcom.com"
subprocess.run(['docker', 'login', helm_repo, '-u', username, '-p', password], check=True, text=True)

def download_chart(url, target_dir):
    local_filename = os.path.join(target_dir, url.split("/")[-1])
    headers = {'Authorization': f"Bearer {token}", 'Accept': 'application/vnd.github+json'}

    with requests.get(url, stream=True, headers=headers) as r:
        r.raise_for_status()
        with open(local_filename, 'wb') as f:
            for chunk in r.iter_content(chunk_size=32768):
                f.write(chunk)
    print(f"Downloaded {local_filename}")
    return local_filename

def chart_exists_in_artifactory(chart_name, version, tmp_dir):
    """Checks if oci://helm_repo/chart_name:version already exists."""
    dest_ref = f"oci://{helm_repo}/{chart_name}"
    check_dir = os.path.join(tmp_dir, "check")
    os.makedirs(check_dir, exist_ok=True)
    res = subprocess.run(
        ['helm', 'pull', dest_ref, '--version', version, '-d', check_dir],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return res.returncode == 0

def main():
    path = Path(args.index)
    yaml = YAML(typ='safe')
    data = yaml.load(path)

    target_versions = [args.version] if args.version else ALLOWED_VERSIONS
    chart_name = args.chart

    portal_entries = data.get("entries", {}).get(chart_name, [])
    if not portal_entries:
        print(f"No entries found for chart '{chart_name}' in {args.index}")
        return

    with tempfile.TemporaryDirectory() as tmp_dir:
        for entry in portal_entries:
            version = entry.get("version")
            if version not in target_versions:
                continue

            urls = entry.get("urls", [])
            if not urls:
                continue

            url = urls[0]
            print(f"\nChecking {chart_name}:{version}...")

            if chart_exists_in_artifactory(chart_name, version, tmp_dir):
                print(f"-> {chart_name}:{version} already exists in {helm_repo}. Skipping.")
                continue

            print(f"-> Missing in {helm_repo}. Downloading from {url}...")
            chart_file = download_chart(url, tmp_dir)

            print(f"-> Pushing {chart_file} to oci://{helm_repo}")
            subprocess.run(['helm', 'push', chart_file, f"oci://{helm_repo}"], check=True, text=True)

    subprocess.run(['docker', 'logout', helm_repo], check=True, text=True)

if __name__ == "__main__":
    main()
