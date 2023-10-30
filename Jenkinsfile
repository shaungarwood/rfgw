@Library('rig-common')_
pipeline {
  agent {
      node {
          label 'CentOS-7-RUBY233'
      }
  }

  stages {
    stage('bundle') {
      steps {

        /*
         * Delete previous runs, get the repo
        */
        deleteDir()
        checkout scm

        sh 'bundle install'
      }
    }
    /* Not even close :)
    stage('rubocop') {
      steps {
        sh 'bundle exec rake rubocop'
      }
    }
    */

    stage('deploy') {
        when {
            expression {
                env.BRANCH == 'master'
            }
        }
        steps {
            standardGemsPipeline(spaceId: '0a192c60-4193-11e8-be8d-9d0b13e2c9c4', spaceName: '* Rig Gem Build Status')
        }
    }
  }
}
