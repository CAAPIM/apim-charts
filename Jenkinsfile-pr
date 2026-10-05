@Library('apim-jenkins-lib@master') _

// ct, kubeconform and helm aren't installed on the "default" agent, so every
// real check below runs over SSH on a short-lived GCP VM instead - same
// deploy/destroy pattern as layer7-operator-test-automation's Jenkinsfile
// (releng/Self-Service/deploy-gcp-instance, SSH in as the automation-key
// user, tear the VM down in post{cleanup} regardless of outcome).
// debian12-template already has ct + helm baked in (see that repo's
// hack/install-tools.sh); kubeconform.sh downloads its own binary, so no
// extra tool provisioning is needed here.

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
def prCommit = ''

pipeline {
    agent { label "default" }
    environment {
        ARTIFACTORY_RELEASE_LOCAL_REG_HOST = "apim-docker-release-local.usw1.packages.broadcom.com"
    }
    stages {
        stage('Deploy remote VM') {
            when { expression { env.CHANGE_ID } }
            steps {
                script {
                    // Jenkins already ran its implicit SCM checkout for this build
                    // (the merge commit under test) before any stage's steps run.
                    prCommit = env.GIT_COMMIT

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
            when { expression { env.CHANGE_ID } }
            steps {
                script {
                    // Public repo - no credentials needed. A full (non-single-branch)
                    // clone leaves origin/<branch> refs for every branch, which ct
                    // lint and version-check.sh need to diff against
                    // env.CHANGE_TARGET. The PR's own commits aren't reachable from
                    // that plain clone, so they're fetched separately by PR number,
                    // then checked out by the exact commit Jenkins already resolved
                    // (env.GIT_COMMIT, captured above as prCommit).
                    sshCommand remote: remoteSSH, command:
                        "rmdir ${remoteDir} 2>/dev/null; " +
                        "git clone https://github.com/CAAPIM/apim-charts.git ${remoteDir} && " +
                        "cd ${remoteDir} && " +
                        "git fetch origin \"+refs/pull/${env.CHANGE_ID}/*:refs/remotes/origin/pr/${env.CHANGE_ID}/*\" && " +
                        "git checkout ${prCommit}"
                }
            }
        }

        stage('Add helm repos') {
            when { expression { env.CHANGE_ID } }
            steps {
                sshCommand remote: remoteSSH, command: "cd ${remoteDir} && bash .github/helm-repo.sh"
            }
        }

        stage('Chart Lint') {
            // PR-only, matching lint-test.yaml's original scope (it never
            // ran on push - only release.yaml's chart-releaser did, and
            // that's a separate publish concern handled by Jenkinsfile-charts).
            when { expression { env.CHANGE_ID } }
            steps {
                // check-version-increment is handled separately below (ct's
                // own built-in version-increment check has the same
                // classic-repo-only limitation version-check.sh had).
                sshCommand remote: remoteSSH, command:
                    "cd ${remoteDir} && ct lint --config .github/ct-lint.yaml --check-version-increment=false --target-branch ${env.CHANGE_TARGET}"
            }
        }

        stage('Version Check') {
            when { expression { env.CHANGE_ID } }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'ARTIFACTORY_USERNAME_TOKEN', usernameVariable: 'ARTIFACTORY_USER', passwordVariable: 'ARTIFACTORY_APIKEY')
                ]) {
                    sshCommand remote: remoteSSH, command:
                        "cd ${remoteDir} && " +
                        "docker login ${env.ARTIFACTORY_RELEASE_LOCAL_REG_HOST} -u \"${ARTIFACTORY_USER}\" -p \"${ARTIFACTORY_APIKEY}\" && " +
                        "bash .github/version-check.sh ${env.CHANGE_TARGET} ${env.ARTIFACTORY_RELEASE_LOCAL_REG_HOST} && " +
                        "docker logout ${env.ARTIFACTORY_RELEASE_LOCAL_REG_HOST}"
                }
            }
        }

        stage('Kubeconform') {
            when { expression { env.CHANGE_ID } }
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
