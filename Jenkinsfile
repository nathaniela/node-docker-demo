
pipeline {
  options {
    /* Build auto timeout */
    timeout(time: 60, unit: 'MINUTES')
  }

  agent { node { label 'master' } }

  // Pipeline stages
  stages {
    stage('Setup') {
      steps {
        echo "Check out code"
        script {
          scmVars = checkout scm
        }
      }
    }
  }
}

// Utility functions
def get_branch_type(String branch_name) {

    def dev_pattern = "develop"
    def release_pattern = "release/.*"
    def feature_pattern = "feature/.*"
    def hotfix_pattern = "hotfix/.*"
    def master_pattern = "master"
    if (branch_name =~ dev_pattern) {
        return "dev"
    } else if (branch_name =~ release_pattern) {
        return "release"
    } else if (branch_name =~ master_pattern) {
        return "master"
    } else if (branch_name =~ feature_pattern) {
        return "feature"
    } else if (branch_name =~ hotfix_pattern) {
        return "hotfix"
    } else {
        return null;
    }
}

def get_branch_deployment_environment(String branch_type) {
    if (branch_type == "dev") {
        return "dev"
    } else if (branch_type == "release") {
        return "staging"
    } else if (branch_type == "master") {
        return "prod"
    } else {
        return null;
    }
}
