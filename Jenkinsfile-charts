pipeline {
  agent { label 'default' }
  options {
    timeout(time: 15, unit: 'MINUTES')
  }
  environment {
    ARTIFACTORY_CREDS = credentials("ARTIFACTORY_USERNAME_TOKEN")
    GITHUB_CREDS = credentials("GITHUB_CAAPIM_TOKEN")
    GITHUB_TOKEN = "${GITHUB_CREDS_PSW}"
  }
  stages {
    stage('Push Helm Charts') {
      steps {
        sh("pip3 install requests ruamel.yaml")
        sh("python3 push_helm_charts.py --release")
      }
    }
  }
}
