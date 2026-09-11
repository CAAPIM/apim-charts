@Library('apim-jenkins-lib@master') _

pipeline {
    agent { label "default" }
    environment {
        ARTIFACTORY_RELEASE_LOCAL_REG_HOST = "apim-docker-release-local.usw1.packages.broadcom.com"
    }
    stages {
        stage('Add helm repos') {
            when { expression { env.CHANGE_ID } }
            steps {
                sh '.github/helm-repo.sh'
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
                sh "ct lint --config .github/ct-lint.yaml --check-version-increment=false --target-branch ${env.CHANGE_TARGET}"
            }
        }
        stage('Version Check') {
            when { expression { env.CHANGE_ID } }
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'ARTIFACTORY_USERNAME_TOKEN', usernameVariable: 'ARTIFACTORY_USER', passwordVariable: 'ARTIFACTORY_APIKEY')
                ]) {
                    sh '''
                    docker login ${ARTIFACTORY_RELEASE_LOCAL_REG_HOST} -u ${ARTIFACTORY_USER} -p ${ARTIFACTORY_APIKEY}
                    .github/version-check.sh ${CHANGE_TARGET} ${ARTIFACTORY_RELEASE_LOCAL_REG_HOST}
                    docker logout ${ARTIFACTORY_RELEASE_LOCAL_REG_HOST}
                    '''
                }
            }
        }
        stage('Kubeconform') {
            when { expression { env.CHANGE_ID } }
            steps {
                sh '.github/kubeconform.sh'
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
    }
}
