# Package this repo's helm charts from the workspace and push them to
# Artifactory as OCI artifacts - but only charts that are actually new
# versions.
#
# Pre-requisite:
# - Artifactory credentials set in environment: ARTIFACTORY_CREDS_USR, ARTIFACTORY_CREDS_PSW
# - `ct` (chart-testing) on PATH if --check-changed is used
#
# command examples:
# python3 push_helm_charts.py
# python3 push_helm_charts.py --release
# python3 push_helm_charts.py --check-changed stable

import argparse
import os
import subprocess
import sys
import tempfile

# apim-intelligence was a separate chart/dependency at one point but is now
# built directly into the portal chart's own templates - no source left to
# package. gateway-otk was deprecated last year and was never in this list.
CHARTS = ["druid", "gateway", "portal", "seaweedfs", "kafka"]

parser = argparse.ArgumentParser(description="Package and push this repo's helm charts to artifactory, for versions that are new")
parser.add_argument('--charts-dir', default='charts', help='directory containing the charts to package')
parser.add_argument('--release', action='store_true', help='flag to push to release repo instead of dev')
parser.add_argument('--check-changed', metavar='TARGET_BRANCH', default=None,
                     help='only publish charts `ct list-changed --target-branch TARGET_BRANCH` reports as '
                          'changed (cheap short-circuit for PR builds; meaningless when already on the target '
                          'branch itself, so omit it there)')

args = parser.parse_args()
username = os.getenv('ARTIFACTORY_CREDS_USR')
password = os.getenv('ARTIFACTORY_CREDS_PSW')
if not username or not password:
    sys.exit("please set env for ARTIFACTORY_CREDS_USR and ARTIFACTORY_CREDS_PSW")
helm_stage = "release" if args.release else "dev"
helm_repo = f"apim-docker-{helm_stage}-local.usw1.packages.broadcom.com"

def changed_charts(charts_dir, target_branch):
    result = subprocess.run(['ct', 'list-changed', '--target-branch', target_branch],
                             check=True, text=True, capture_output=True)
    changed_dirs = {line.strip() for line in result.stdout.splitlines()}
    return [c for c in CHARTS if f"{charts_dir}/{c}" in changed_dirs]

def chart_metadata(chart_dir):
    name = version = None
    with open(os.path.join(chart_dir, "Chart.yaml")) as f:
        for line in f:
            if line.startswith("name:"):
                name = line.split(":", 1)[1].strip()
            elif line.startswith("version:"):
                version = line.split(":", 1)[1].strip()
    if not name or not version:
        sys.exit(f"could not read name/version from {chart_dir}/Chart.yaml")
    return name, version

def version_exists(chart_name, version):
    # Mirrors chart-releaser's own "don't recreate an existing release" check,
    # just against the Artifactory OCI repo instead of GitHub Releases.
    with tempfile.TemporaryDirectory() as tmpdir:
        result = subprocess.run(
            ['helm', 'pull', f"oci://{helm_repo}/{chart_name}", '--version', version, '-d', tmpdir],
            text=True, capture_output=True)
        return result.returncode == 0

def package_chart(chart_dir):
    result = subprocess.run(['helm', 'package', chart_dir], check=True, text=True, capture_output=True)
    print(result.stdout)
    # `helm package` prints "Successfully packaged chart and saved it to: <path>"
    return result.stdout.strip().rsplit(": ", 1)[-1]

def publish_chart(chart_dir):
    chart_name, version = chart_metadata(chart_dir)
    if version_exists(chart_name, version):
        print(f"{chart_name} {version} already published to {helm_repo} - skipping")
        return
    print(f"working on {chart_name} {version} from {chart_dir}")
    packaged_chart = package_chart(chart_dir)
    subprocess.run(['helm', 'push', packaged_chart, f"oci://{helm_repo}"], check=True, text=True)

def main():
    charts_to_publish = CHARTS
    if args.check_changed:
        charts_to_publish = changed_charts(args.charts_dir, args.check_changed)
        if not charts_to_publish:
            print(f"no chart changes vs {args.check_changed} - skipping publish")
            return

    subprocess.run(['docker', 'login', helm_repo, '-u', username, '-p', password], check=True, text=True)
    try:
        for chart in charts_to_publish:
            publish_chart(os.path.join(args.charts_dir, chart))
    finally:
        subprocess.run(['docker', 'logout', helm_repo], check=True, text=True)

if __name__ == "__main__":
    main()
