
pipeline {
  options {
    /* Build auto timeout */
    timeout(time: 60, unit: 'MINUTES')
  }

  environment {
    registry = "nathanielassis/node-docker-demo"
    registryCredential = 'dockerhub'
  }

  agent { node { label 'master' } }

  // Pipeline stages
  stages {
    stage('Setup') {
      steps {
        script {
          echo "Check out code"
          scmVars = checkout scm

          GIT_BRANCH_TYPE = get_branch_type("${scmVars.GIT_BRANCH}")
          echo "GIT_BRANCH_TYPE is: ${GIT_BRANCH_TYPE}"

          DEPLOY_ENV = get_branch_deployment_environment("${GIT_BRANCH_TYPE}")
          echo "DEPLOY_ENV is: ${DEPLOY_ENV}"

          GIT_TAG = "${scmVars.GIT_TAG}"
          echo "GIT_TAG is: ${GIT_TAG}"

          GIT_BRANCH = sh (
            script: "echo ${scmVars.GIT_BRANCH} | cut -d '/' -f 2",
            returnStdout: true
          ).trim()
          echo "GIT_BRANCH is: ${GIT_BRANCH}"

          GIT_COMMIT = sh (
            script: "git rev-parse --short HEAD",
            returnStdout: true
            ).trim()
          echo "GIT_COMMIT is: ${GIT_COMMIT}"

        }
      }
    }

    stage('Build image') {
      steps {
          echo "Building application and Docker image"
          script {
            // building docker image only if branch is either development or release (staging)
            if ( "${GIT_BRANCH_TYPE}" == 'feature' || "${GIT_BRANCH_TYPE}" == 'release' ) { // TODO: change to dev
              image = docker.build("${env.registry}:${GIT_COMMIT}")
            }
          }
      }
    }

    stage('Test image') {
        steps {
          echo 'echo "Add tests here"'
        }
    }

    stage('Push image') {
        steps {
          script {
            docker.withRegistry("https://registry.hub.docker.com", "${env.registryCredential}") {
              if ( "${GIT_BRANCH_TYPE}" == 'master' && "${GIT_TAG}" != '' ) {
                image.push("${GIT_TAG}")
              } else if ( "${GIT_BRANCH_TYPE}" == 'master' && "${GIT_TAG}" == '' ) {
                  echo "WARNING: commit on master branch without a release TAG, doing nothing."
              }
              if ( "${GIT_BRANCH_TYPE}" == 'release' ) {
                echo "Pushing docker image to ${registry} from release branch."
                /* rc - release candidate */
                image.push("rc-${GIT_BRANCH}-${GIT_COMMIT}")
              }
              if ( "${GIT_BRANCH_TYPE}" == 'dev' ) {
                echo "Pushing docker image to ${registry} from develop branch."
                image.push("dev-${GIT_BRANCH}-${GIT_COMMIT}")
              }
            }
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

def check_merge_source_details() {
    /*
    If the commit is a result of a Merge,
    it will return the commit id and the branch name which are the source of the merge.
    */
    if (`git show --summary HEAD | grep -q ^Merge:`) {
        SRC_COMMIT=`git show --summary HEAD | grep ^Merge: | awk '{print $3}'`
        SRC_BRANCH=`git branch --contains ${SRC_COMMIT} | grep -v master`
        return ["${SRC_BRANCH}, ${SRC_COMMIT}"]
    } else {
        return "NOT_MERGE_COMMIT"
    }
}
