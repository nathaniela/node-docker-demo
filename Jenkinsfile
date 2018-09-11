
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
            if ( "${GIT_BRANCH_TYPE}" == 'dev' || "${GIT_BRANCH_TYPE}" == 'release' ) {
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
              if ( "${GIT_BRANCH_TYPE}" == 'master' && "check_merge_commit()" && "${GIT_TAG}" != null) {
                src_commit = get_merge_source_commit()
                //src_branch = get_branch_by_commit("${src_commit}")
                src_branch = 'release/v1.0.1'
                src_branch_short_name = sh (
                  script: "echo ${src_branch} | cut -d '/' -f 2",
                  returnStdout: true
                ).trim()
                echo "Please notice the source commit (${src_commit}), source branch (${src_branch}), and git tag ${GIT_TAG}"
                //tag the container with the release tag.
                pullAndPushImage("${env.registry}:rc-${src_branch_short_name}-${src_commit}", "${env.registry}:${GIT_TAG}")

              } else if ( "${GIT_BRANCH_TYPE} == 'master' && ${GIT_TAG} == null" ) {
                echo "WARNING: no release TAG found, doing nothing."
              }
              if ( "${GIT_BRANCH_TYPE}" == 'release' ) {
                echo "Pushing docker image to ${registry} from release branch."
                /* rc - release candidate */
                image.push("rc-${GIT_BRANCH}-${GIT_COMMIT}")
              }
              if ( "${GIT_BRANCH_TYPE}" == 'dev' ) {
                echo "Pushing docker image to ${registry} from develop branch."
                image.push("${GIT_BRANCH_TYPE}-${GIT_COMMIT}")
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
  src_commit = sh (
    script: "git show --summary HEAD | grep ^Merge: | awk \'{print \$3}\'",
    returnStdout: true
    ).trim()
  return "${src_commit}"
}

def get_branch_by_commit(src_commit) {
    /*
    Find the source branch of a commit
    We exclude the master branch as it will always appear as part of the merge commit
    */
    src_branch = sh (
      script: "git branch --contains ${src_commit} | grep -v master",
      returnStdout: true
      ).trim()
    echo "Source branch found: ${src_branch}"
    return "${src_branch}"
}

def check_merge_commit() {
    /*
    If the commit is a result of a Merge,
    it will return the commit id and the branch name which are the source of the merge.
    */
    def merge = sh returnStatus: true, script: "git show --summary HEAD | grep -q ^Merge:"

    return "${merge}"
}

/**
 * If a production tag is found see if it is found in the ecr repository.
*/
Boolean repoHasTaggedImage(String target) {
  // deconstruct target
  // todo would be better to have these variables passed to the function
  (ecrEndpoint, tag) = target.split(':')
  region = ecrEndpoint.split(/\./)[3]
  repository = ecrEndpoint.split('/')[1]

    // check if the image exists
  try {
      image = sh(
          returnStdout: true,
          script: "aws ecr describe-images \
          --profile=liveperson_prod \
          --repository-name=${repository} \
          --region=${region} \
          --image-ids=\"imageTag=${tag}\""
          )
      // return without pushing and pulling
      echo "Image found:"
      echo image
      return true
  } catch (Exception e) {
      echo "Image not found in repository."
  }
  return false
}

def pullAndPushImage(source, target){

  //if (repoHasTaggedImage(target) == true)
  //  return true
  docker.withRegistry("https://registry.hub.docker.com", "${env.registryCredential}") {
    try {
      sh "docker pull ${source}"
      sh "docker tag ${source} ${target}"
      sh "docker push ${target}"
    } finally {
      sh 'docker images | egrep "(day|week|month|year)" | awk \'{ print $3 }\' | xargs -rL1 docker rmi -f 2>/dev/null || true' // clean old images
    }
  }
}
