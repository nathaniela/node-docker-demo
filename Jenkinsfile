#!/usr/bin/env groovy
pipeline {
  options {
    // Set log rotation, timeout and timestamps in the console
    buildDiscarder(logRotator(numToKeepStr:'10'))
    disableConcurrentBuilds()
    timestamps()
    timeout(time: 60, unit: 'MINUTES')
  }

  environment {
    registry = "nathanielassis/node-docker-demo"
    registryCredential = 'dockerhub'
  }

  triggers {
    pollSCM('H/2 * * * *')
  }

  agent { node { label 'master' } }

  // Pipeline stages
  stages {
    stage('Setup') {
      steps {
        script {
          echo "Check out code"
          scmVars = checkout scm

          echo "scmVars is: ${scmVars}"

          GIT_BRANCH_TYPE = get_branch_type("${scmVars.GIT_BRANCH}")
          echo "GIT_BRANCH_TYPE is: ${GIT_BRANCH_TYPE}"

          gitBranchType = get_branch_type("${scmVars.GIT_BRANCH}")
          echo "gitBranchType is: ${gitBranchType}"

          deployEnv = get_branch_deployment_environment("${gitBranchType}")
          echo "Deployment Environment is: ${deployEnv}"

          gitReleaseTag = sh ( /* TODO: get rid of this logic */
            script: "git describe --tags --abbrev=0 --always",
            returnStdout: true
            ).trim()
          echo "gitReleaseTag is: ${gitReleaseTag}"

          gitBranch = sh (
            script: "echo ${scmVars.GIT_BRANCH} | cut -d '/' -f 2",
            returnStdout: true
          ).trim()
          echo "gitBranch is: ${gitBranch}"

          gitCommit = sh (
            script: "git rev-parse --short HEAD",
            returnStdout: true
            ).trim()
          echo "gitCommit is: ${gitCommit}"

        }
      }
    }

    stage('Build image') {
      steps {
          echo "Building application and Docker image"
          script {
            // building docker image only if branch is either development or release (staging)
            if ( "${gitBranchType}" == 'dev' || "${gitBranchType}" == 'release' ) {
              image = docker.build("${env.registry}")
            } else {
              echo "Only develop, release branches run docker build, skipping."
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
              if ( "${gitBranchType}" == 'master' && "${check_merge_commit()}") {
                srcCommit = get_merge_source_commit()
                srcBranch = get_branch_by_commit()
                echo "Please notice the source commit (${srcCommit}), source branch (${srcBranch}), and git tag ${gitReleaseTag}"
                withCredentials([string(credentialsId: 'docker-registry-password', variable: 'PW1')]) {
                  try {
                    sh "docker login -u nathanielassis -p ${PW1} https://registry.hub.docker.com"
                    sh "docker pull registry.hub.docker.com/${registry}:rc-${srcBranch}-${srcCommit}"
                    sh "docker tag registry.hub.docker.com/${registry}:rc-${srcBranch}-${srcCommit} registry.hub.docker.com/${registry}:${srcBranch}"
                    sh "docker push registry.hub.docker.com/${registry}:${srcBranch}"
                  } finally {
                    sh 'docker images | egrep "(day|week|month|year)" | awk \'{ print $3 }\' | xargs -rL1 docker rmi -f 2>/dev/null || true' // clean old images
                  }
                }

              } else if ( "${gitBranchType} == 'master' && ${gitReleaseTag} == null" ) {
                echo "WARNING: no release TAG found, doing nothing."
              }
              if ( "${gitBranchType}" == 'release' ) {
                echo "Pushing docker image to ${registry} from release branch."
                /* rc - release candidate */
                image.push("rc-${gitBranch}-${gitCommit}")
              }
              if ( "${gitBranchType}" == 'dev' ) {
                echo "Pushing docker image to ${registry} from develop branch."
                image.push("${gitBranchType}-${gitCommit}")
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

def get_merge_source_commit() {
  srcCommit = sh (
    script: "git show --summary HEAD | grep ^Merge: | awk \'{print \$3}\'",
    returnStdout: true
    ).trim()

  echo "get_merge_source_commit: merge source commit is: ${srcCommit}"
  return "${srcCommit}"
}

def get_branch_by_commit() {
    /*
    Find the source branch of a commit which is the source of a pull request
    We exclude the master branch as it will always appear as part of the merge commit
    */
    def out = sh (
      script: "git show --summary HEAD | grep 'pull request' | cut -d '/' -f 3",
      returnStdout: true
    ).trim()

    echo "get_branch_by_commit: source branch is: ${out}"
    return "${out}"
}

def check_merge_commit() {
    /*
    If the commit is a result of a Merge,
    it will return the commit id and the branch name which are the source of the merge.
    */
    echo "check_merge_commit: Checking if commit is part of a Merge."
    def merge = sh returnStatus: true, script: "git show --summary HEAD | grep -q ^Merge:"

    if ( "$merge" == 0 ) {
        echo "check_merge_commit: commit is part of a pull request == true"
        return true
    } else {
        echo "check_merge_commit: commit is NOT part of a pull request == false"
        return false
    }
}
