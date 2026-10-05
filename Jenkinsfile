@Library('apim-jenkins-lib@master') _

// TEMPORARY test-only copy of Jenkinsfile-pr, for validating the remote-VM
// mechanics (deploy/SSH/destroy) directly on this branch before opening a PR.
// All `when { expression { env.CHANGE_ID } }` guards are removed so every
// stage runs on a plain branch build. TARGET_BRANCH replaces env.CHANGE_TARGET
// for the diff-based checks (ct lint / version-check.sh), since there's no PR
// to supply it. Once validated, this file goes away and Jenkinsfile-pr moves
// back to being Jenkinsfile.
//
// ct, kubeconform and helm aren't installed on the "default" agent (it's a
// container, so no docker-in-docker option either), so every real check
// below runs over SSH on a short-lived GCP VM instead
// (releng/Self-Service/deploy-gcp-instance, debian12-template, SSH in as the
// automation-key user, tear the VM down in post{cleanup} regardless of
// outcome).

import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Calendar

DateFormat dateFormat = new SimpleDateFormat("yyMMdd")
Calendar calendar = Calendar.getInstance()
def today = dateFormat.format(calendar.getTime())

def GCP_TEMPLATE = 'debian12-template'
def GCP_SCHEDULE = 'always-on' // VM is destroyed explicitly in post{cleanup}; the schedule is not relied on for teardown
def VM_CPU = '2'
def VM_MEM = '4096'

def remoteHostInstanceName = ''
def remoteHostIP = ''
def remoteSSH = [:]
def remoteUser = ''
def remoteDir = ''
def builtCommit = ''

pipeline {
    agent { label "default" }
    parameters {
        string(name: 'TARGET_BRANCH', defaultValue: 'stable',
               description: 'Branch to diff changed charts against for ct lint / version-check.sh (stands in for env.CHANGE_TARGET, which only exists on PR builds)')
    }
    environment {
        ARTIFACTORY_RELEASE_LOCAL_REG_HOST = "apim-docker-release-local.usw1.packages.broadcom.com"
    }
    stages {
        stage('Deploy remote VM') {
            steps {
                script {
                    // Jenkins already ran its implicit SCM checkout for this build
                    // before any stage's steps run.
                    builtCommit = env.GIT_COMMIT

                    remoteHostInstanceName = "apimcharts-${today}-${BUILD_NUMBER}"
                    withCredentials([
                        sshUserPrivateKey(credentialsId: 'AUTOMATION_SSH_KEY', keyFileVariable: 'automationKey',
                                           passphraseVariable: '', usernameVariable: 'automationUser'),
                        string(credentialsId: 'AUTOMATION_SSH_PUBLIC_KEY', variable: 'sshPubKey')
                    ]) {
                        remoteUser = "${automationUser}"
                        // Persist a copy of the private key for the rest of the build — the
                        // withCredentials-bound file is deleted as soon as this block exits.
                        sh "install -m 600 ${automationKey} ${WORKSPACE}/automation_key"

                        built = build job: 'releng/Self-Service/deploy-gcp-instance/develop',
                            parameters: [
                                string(name: 'vm_name', value: "${remoteHostInstanceName}"),
                                string(name: 'vm_cpu', value: VM_CPU),
                                string(name: 'vm_mem', value: VM_MEM),
                                string(name: 'gcp_machine_image', value: GCP_TEMPLATE),
                                string(name: 'gcp_instance_schedule', value: GCP_SCHEDULE),
                                string(name: 'ssh_user', value: "${automationUser}"),
                                base64File(name: 'ssh_public_key', base64: sshPubKey.bytes.encodeBase64().toString())
                            ]
                    }
                    copyArtifacts(projectName: 'releng/Self-Service/deploy-gcp-instance/develop', selector: specific("${built.number}"))
                    remoteHostIP = sh(script: "ls -af|grep 10.|tr -d '\n'", returnStdout: true).trim()
                    echo "remote host: ${remoteHostInstanceName} (${remoteHostIP})"
                    sh 'sleep 20' // let sshd come up

                    remoteSSH.name = 'apim-charts-lint'
                    remoteSSH.host = "${remoteHostIP}"
                    remoteSSH.allowAnyHosts = true
                    remoteSSH.user = remoteUser
                    remoteSSH.identityFile = "${WORKSPACE}/automation_key"

                    remoteDir = "/home/${remoteUser}/apim-charts-${BUILD_NUMBER}"
                    sshCommand remote: remoteSSH, command: "mkdir -p ${remoteDir}" // connectivity smoke test
                }
            }
        }

        stage('Fetch source') {
            steps {
                script {
                    // Public repo - no credentials needed. Full (non-single-branch)
                    // clone so origin/${TARGET_BRANCH} exists locally for ct lint's
                    // and version-check.sh's diff-against-target-branch checks, then
                    // check out the exact commit this build is running against.
                    sshCommand remote: remoteSSH, command:
                        "rmdir ${remoteDir} 2>/dev/null; " +
                        "git clone https://github.com/CAAPIM/apim-charts.git ${remoteDir} && " +
                        "cd ${remoteDir} && git checkout ${builtCommit}"
                }
            }
        }

        stage('Version Check') {
            // Runs BEFORE Chart Lint, not after: ct lint's `helm dependency build`
            // repackages any chart's local file://-path dependencies (e.g. portal's
            // druid/seaweedfs/kafka) from scratch, and that repackaged .tgz is never
            // byte-identical to the one committed in git (tar/gzip embed timestamps),
            // even when the source is unchanged. That dirties the working tree this
            // stage's git diff -- charts/<chart> relies on, producing a false
            // "changes detected" for any chart with local-path deps. Running this
            // first, against the untouched clone, avoids that entirely.
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'ARTIFACTORY_USERNAME_TOKEN', usernameVariable: 'ARTIFACTORY_USER', passwordVariable: 'ARTIFACTORY_APIKEY')
                ]) {
                    sshCommand remote: remoteSSH, command:
                        "cd ${remoteDir} && " +
                        "docker login ${env.ARTIFACTORY_RELEASE_LOCAL_REG_HOST} -u \"${ARTIFACTORY_USER}\" -p \"${ARTIFACTORY_APIKEY}\" && " +
                        "bash .github/version-check.sh ${params.TARGET_BRANCH} ${env.ARTIFACTORY_RELEASE_LOCAL_REG_HOST} && " +
                        "docker logout ${env.ARTIFACTORY_RELEASE_LOCAL_REG_HOST}"
                }
            }
        }

        stage('Add helm repos') {
            steps {
                sshCommand remote: remoteSSH, command: "cd ${remoteDir} && bash .github/helm-repo.sh"
            }
        }

        stage('Chart Lint') {
            steps {
                // ct's chart_schema.yaml/lintconf.yaml defaults aren't bundled with
                // whatever installed the `ct` binary already on this VM, so ct fails
                // with "neither specified nor found in default locations" without
                // them. GH Actions' chart-testing-action never hits this because it
                // installs ct from its official release tarball, which DOES bundle
                // etc/chart_schema.yaml + etc/lintconf.yaml alongside the binary. Doing
                // the same thing here: ask the VM's own `ct version` which release to
                // fetch, pull just those two files from that same public tarball, and
                // point ct at them explicitly - no files added to this repo.
                sshCommand remote: remoteSSH, command:
                    "cd ${remoteDir} && " +
                    "CT_TAG=\$(ct version | awk '/^Version:/{print \$2}') && " +
                    "CT_VER=\${CT_TAG#v} && " +
                    "ARCH=\$(uname -m) && " +
                    "case \"\$ARCH\" in x86_64) CTARCH=amd64 ;; aarch64|arm64) CTARCH=arm64 ;; *) CTARCH=\$ARCH ;; esac && " +
                    "curl -fsSL -o /tmp/ct.tgz \"https://github.com/helm/chart-testing/releases/download/\${CT_TAG}/chart-testing_\${CT_VER}_linux_\${CTARCH}.tar.gz\" && " +
                    "mkdir -p /tmp/ct-config && tar -xzf /tmp/ct.tgz -C /tmp/ct-config etc/chart_schema.yaml etc/lintconf.yaml && " +
                    "ct lint --config .github/ct-lint.yaml " +
                    "--chart-yaml-schema /tmp/ct-config/etc/chart_schema.yaml --lint-conf /tmp/ct-config/etc/lintconf.yaml " +
                    "--check-version-increment=false --target-branch ${params.TARGET_BRANCH}"
            }
        }

        stage('Kubeconform') {
            steps {
                sshCommand remote: remoteSSH, command: "cd ${remoteDir} && bash .github/kubeconform.sh"
            }
        }
    }

    post {
        success {
            script {
                // send commit status to repo when the build is a pull request
                if (env.CHANGE_ID) {
                    pullRequest.createStatus(status: 'success',
                            context: 'continuous-integration/jenkins/pr-merge',
                            description: 'Build Success',
                            targetUrl: "${env.JOB_URL}/testResults")
                }
            }
        }
        failure {
            script {
                if (env.CHANGE_ID) {
                    pullRequest.createStatus(status: 'failure',
                            context: 'continuous-integration/jenkins/pr-merge',
                            description: 'Build Failed',
                            targetUrl: "${env.JOB_URL}/testResults")
                }
            }
        }
        always {
            script {
                try { sh "rm -f ${WORKSPACE}/automation_key" } catch (Exception e) { echo "key cleanup failed: ${e}" }
            }
        }
        cleanup {
            script {
                // cleanup runs after every other post condition, regardless of pipeline/stage/post result,
                // so the GCP VM teardown can't be skipped by an earlier failure.
                if (remoteHostInstanceName) {
                    try {
                        build job: 'releng/Self-Service/destroy-gcp-instance/develop',
                                propagate: false,
                                wait: true,
                                parameters: [
                                        string(name: 'INSTANCE_NAME', value: "${remoteHostInstanceName}")
                                ]
                        echo "${remoteHostInstanceName}* is destroyed..."
                    } catch (Exception e) {
                        echo "Deleting ${remoteHostInstanceName} gcp VM failed. Exception: ${e}"
                    }
                }
            }
        }
    }
}
