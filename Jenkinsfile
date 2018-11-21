pipeline {
    agent any
    environment {
      ORG               = 'xieweicarl2018'
      APP_NAME          = 'rust-http'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          // seems we need to upgrade rust else we get compile errors using Rust 1.24.1
          sh 'rustup override set nightly'
          sh "cargo install"
          sh "cp ~/.cargo/bin/rust-http ."

          sh 'export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml'
          sh "jx step validate --min-jx-version 1.2.36"
          sh "jx step post build --image \$DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"

          dir ('./charts/preview') {
            sh "make preview"
            sh "jx preview --app $APP_NAME --dir ../.."
          }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          git 'https://github.com/xieweicarl2018/rust-http.git'
          // so we can retrieve the version in later steps
          sh "echo \$(jx-release-version) > VERSION"
          dir ('./charts/rust-http') {
            sh "make tag"
          }
          // seems we need to upgrade rust else we get compile errors using Rust 1.24.1
          sh 'rustup override set nightly'
          sh "cargo install"
          sh "cp ~/.cargo/bin/rust-http ."

          sh 'export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml'
          sh "jx step validate --min-jx-version 1.2.36"
          sh "jx step post build --image \$DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
        }
      }
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          dir ('./charts/rust-http') {
            sh 'jx step changelog --version \$(cat ../../VERSION)'

            // release the helm chart
            sh 'make release'

            // promote through all 'Auto' promotion Environments
            sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION) --no-wait'
          }
        }
      }
    }
  }
