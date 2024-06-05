# Download latest released apim helm charts from github.com and push to artifactory
#
# Pre-requisite:
# - The gh-pages index.yaml file available
# - Artifactory credentials set in environment: ARTIFACTORY_CREDS_USR, ARTIFACTORY_CREDS_PSW
# - GitHub access token set in environment: GITHUB_TOKEN
#
# command examples:
# python3 push_helm_charts.py --index index.yaml

import argparse
import os
import requests
import subprocess
from pathlib import Path
from ruamel.yaml import YAML

parser = argparse.ArgumentParser(description='Push apim helm charts to artifactory')
parser.add_argument('--index', default='index.yaml', help='index file to read for chart releases')
parser.add_argument('--release', action='store_true', help='flag to push to release repo instead of dev')

args = parser.parse_args()
username = os.getenv('ARTIFACTORY_CREDS_USR')
password = os.getenv('ARTIFACTORY_CREDS_PSW')
token = os.getenv('GITHUB_TOKEN')
if not username or not password or not token:
    sys.exit("please set env for ARTIFACTORY_CREDS_USR, ARTIFACTORY_CREDS_PSW, and GITHUB_TOKEN")
helm_stage = "release" if args.release else "dev"
helm_repo = f"apim-docker-{helm_stage}-local.usw1.packages.broadcom.com"
subprocess.run(['docker', 'login', helm_repo, '-u', username, '-p', password], check=True, text=True)

def download_chart(url):
    local_filename = url.split("/")[-1]
    headers = {'Authorization': f"Bearer {token}", 'Accept': 'application/vnd.github+json'}

    # download file
    with requests.get(url, stream=True, headers=headers) as r:
        r.raise_for_status()
        with open(local_filename, 'wb') as f:
            for chunk in r.iter_content(chunk_size=32768):
                f.write(chunk)
    print(f"downloaded {local_filename}")
    return local_filename

def main():
    path = Path(args.index)
    yaml = YAML(typ='safe')
    data = yaml.load(path)
    druid_url = data["entries"]["druid"][0]["urls"][0]
    gateway_url = data["entries"]["gateway"][0]["urls"][0]
    portal_url = data["entries"]["portal"][0]["urls"][0]

    print(f"working on druid: {druid_url}")
    druid_chart = download_chart(druid_url)
    subprocess.run(['helm', 'push', druid_chart, f"oci://{helm_repo}"], check=True, text=True)
    print(f"working on gateway: {gateway_url}")
    gateway_chart = download_chart(gateway_url)
    subprocess.run(['helm', 'push', gateway_chart, f"oci://{helm_repo}"], check=True, text=True)
    print(f"working on portal: {portal_url}")
    portal_chart = download_chart(portal_url)
    subprocess.run(['helm', 'push', portal_chart, f"oci://{helm_repo}"], check=True, text=True)

    subprocess.run(['docker', 'logout', helm_repo], check=True, text=True)

if __name__ == "__main__":
    main()
