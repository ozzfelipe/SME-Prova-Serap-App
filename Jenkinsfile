pipeline {  
    environment {
      branchname =  env.BRANCH_NAME.toLowerCase()
    }

    agent {
      node { 
        label 'SME-AGENT-FLUTTER3106'
      }
    }
    
    options {
      buildDiscarder(logRotator(numToKeepStr: '5', artifactNumToKeepStr: '5'))
      disableConcurrentBuilds()
      skipDefaultCheckout()  
    }

    stages {
       stage('CheckOut') {
        steps {
          checkout scm
          script {
            sh("pwd")
            sh("ls -ltra")
            APP_VERSION = sh(returnStdout: true, script: "cat pubspec.yaml | grep version: | awk '{print \$2}'") .trim()
            sh("echo ${APP_VERSION}")
            sh("echo ${BUILD_NUMBER}")
            }
        }
      }

      stage('Build APK Dev') {
        when { 
          anyOf { 
            branch 'development'; 
          } 
        }       
        steps {
          withCredentials([
            file(credentialsId: 'serap-app-google-service-dev', variable: 'GOOGLEJSONDEV'),
            //file(credentialsId: 'serap-app-config-dev', variable: 'APPCONFIGDEV'),
            file(credentialsId: 'app-key-jks', variable: 'APPKEYJKS'),
            file(credentialsId: 'app-key-properties', variable: 'APPKEYPROPERTIES'),
            file(credentialsId: 'serap-app-environment-dev', variable: 'ENVDEV'),
    ]) {
            sh 'cp ${APPKEYJKS} ${WORKSPACE}/android/app/key.jks && cp ${APPKEYPROPERTIES} ${WORKSPACE}/android/key.properties'
            sh 'cd ${WORKSPACE}'
            sh 'if [ ! -d "android/app/src/dev" ]; then mkdir android/app/src/dev; fi'
            sh 'cp ${GOOGLEJSONDEV} android/app/src/dev/google-services.json && cp ${ENVDEV} envdev && chmod a+r+x envdev && . $(realpath envdev) && rm -f envdev && touch .env && echo "NOTHINGTODO" > .env'
            sh 'flutter clean'
            sh "flutter pub get && flutter build apk --build-name=${APP_VERSION} --build-number=${BUILD_NUMBER} --release --flavor=dev"
            sh "ls -ltra ${WORKSPACE}/build/app/outputs/flutter-apk/"
            stash includes: 'build/app/outputs/flutter-apk/**/*.apk', name: 'appbuild'
          }
        }
      }

      stage('Build APK Hom') {
        when { 
          anyOf { 
            branch 'release' 
          } 
        }       
        steps {
          withCredentials([
            file(credentialsId: 'serap-app-google-service-hom', variable: 'GOOGLEJSONHOM'),
            file(credentialsId: 'app-key-jks', variable: 'APPKEYJKS'),
            file(credentialsId: 'app-key-properties', variable: 'APPKEYPROPERTIES'),
            file(credentialsId: 'serap-app-environment-hom', variable: 'ENVHOM'),
          ]) {
            sh 'cp ${APPKEYJKS} ${WORKSPACE}/android/app/key.jks && cp ${APPKEYPROPERTIES} ${WORKSPACE}/android/key.properties'
            sh 'cd ${WORKSPACE}'
            sh 'if [ ! -d "android/app/src/hom" ]; then mkdir android/app/src/hom; fi'
            sh 'cp ${GOOGLEJSONHOM} android/app/src/hom/google-services.json && cp ${ENVHOM} envhom && chmod a+r+x envhom && . $(realpath envhom) && rm -f envhom && touch .env && echo "NOTHINGTODO" > .env'
            sh 'flutter clean'
            sh "flutter pub get && flutter build apk --build-name=${APP_VERSION} --build-number=${BUILD_NUMBER} --release --flavor=hom"
            sh "ls -ltra ${WORKSPACE}/build/app/outputs/flutter-apk/"
            stash includes: 'build/app/outputs/flutter-apk/**/*.apk', name: 'appbuild'
          }
        }
      }
      
      stage('Build APK Prod') {
        when {
          branch 'master'
        }
        steps {
          withCredentials([
            file(credentialsId: 'serap-app-google-service-prod', variable: 'GOOGLEJSONPROD'),
            file(credentialsId: 'app-key-jks', variable: 'APPKEYJKS'),
            file(credentialsId: 'app-key-properties', variable: 'APPKEYPROPERTIES'),
            file(credentialsId: 'serap-app-environment-prod', variable: 'ENVPROD'),
          ]) {
            sh 'cp ${APPKEYJKS} ${WORKSPACE}/android/app/key.jks && cp ${APPKEYPROPERTIES} ${WORKSPACE}/android/key.properties'
            sh 'cd ${WORKSPACE}'            
            sh 'if [ ! -d "android/app/src/prod" ]; then mkdir android/app/src/prod; fi'
            sh 'cp ${GOOGLEJSONPROD} android/app/src/prod/google-services.json && cp ${ENVPROD} envprod && chmod a+r+x envprod && . $(realpath envprod) && rm -f envprod && touch .env && echo "NOTHINGTODO" > .env'
            sh 'flutter clean'
            sh "flutter pub get && flutter build apk --build-name=${APP_VERSION} --build-number=${BUILD_NUMBER} --release --flavor=prod"
            sh "ls -ltra ${WORKSPACE}/build/app/outputs/flutter-apk/"
            sh 'if [ -d "config" ]; then rm -Rf config; fi'
            stash includes: 'build/app/outputs/flutter-apk/**/*.apk', name: 'appbuild'
          }
        }
      }

      stage('Tag Github Dev') {
        agent { label 'master' }
        when { anyOf {  branch 'development'; }}
        steps{
          script{
            try {
              withCredentials([string(credentialsId: "github_token_serap_app", variable: 'token')]) {
                sh("github-release release --security-token "+"$token"+" --user prefeiturasp --repo SME-Prova-Serap-App --tag ${APP_VERSION}-dev --name app-${APP_VERSION}-dev")
              }
            } 
            catch (err) {
                echo err.getMessage()
            }
          }
        }   
      }

      stage('Tag Github Hom') {
        agent { label 'master' }
        when { anyOf {  branch 'release'; }}
        steps{
          script{
            try {
              withCredentials([string(credentialsId: "github_token_serap_app", variable: 'token')]) {
                sh("github-release release --security-token "+"$token"+" --user prefeiturasp --repo SME-Prova-Serap-App --tag ${APP_VERSION}-hom --name app-${APP_VERSION}-hom")
              }
            } 
            catch (err) {
                echo err.getMessage()
            }
          }
        }   
      }     

      stage('Tag Github Prod') {
        agent { label 'master' }
        when { anyOf {  branch 'master'; }}
        steps{
          script{
            try {
              withCredentials([string(credentialsId: "github_token_serap_app", variable: 'token')]) {
                sh("github-release release --security-token "+"$token"+" --user prefeiturasp --repo SME-Prova-Serap-App --tag ${APP_VERSION}-prod --name app-${APP_VERSION}-prod")
              }
            } 
            catch (err) {
                echo err.getMessage()
            }
          }
        }   
      }   

      stage('Release Github Dev') {
        agent { label 'master' }
        when { anyOf {  branch 'development'; }}
        steps{
          script{
            try {
                withCredentials([string(credentialsId: "github_token_serap_app", variable: 'token')]) {
                    sh ("rm -Rf tmp")
                    dir('tmp'){
                        unstash 'appbuild'
                    }
                    sh ("github-release upload --security-token "+"$token"+" --user prefeiturasp --repo SME-Prova-Serap-App --tag ${APP_VERSION}-dev --name "+"app-${APP_VERSION}-dev.apk"+" --file tmp/build/app/outputs/flutter-apk/app-dev-release.apk --replace")
                }
            } 
            catch (err) {
                echo err.getMessage()
            }
          }
        }   
      }  

      stage('Release Github Hom') {
        agent { label 'master' }
        when { anyOf {  branch 'release'; }}
        steps{
          script{
            try {
                withCredentials([string(credentialsId: "github_token_serap_app", variable: 'token')]) {
                    sh ("rm -Rf tmp")
                    dir('tmp'){
                        unstash 'appbuild'
                    }
                    sh ("echo \"app-${env.branchname}.apk\"")
                    sh ("github-release upload --security-token "+"$token"+" --user prefeiturasp --repo SME-Prova-Serap-App --tag ${APP_VERSION}-hom --name "+"app-${APP_VERSION}-hom.apk"+" --file tmp/build/app/outputs/flutter-apk/app-hom-release.apk --replace")
                }
            } 
            catch (err) {
                echo err.getMessage()
            }
          }
        }   
      }
      
      stage('Release Github Prod') {
        agent { label 'master' }
        when { anyOf {  branch 'master'; }}
        steps{
          script{
            try {
                withCredentials([string(credentialsId: "github_token_serap_app", variable: 'token')]) {
                    sh ("rm -Rf tmp")
                    dir('tmp'){
                        unstash 'appbuild'
                    }
                    sh ("echo \"app-${env.branchname}.apk\"")
                    sh ("github-release upload --security-token "+"$token"+" --user prefeiturasp --repo SME-Prova-Serap-App --tag ${APP_VERSION}-prod --name "+"app-${APP_VERSION}-prod.apk"+" --file tmp/build/app/outputs/flutter-apk/app-release.apk --replace")
                }
            } 
            catch (err) {
                echo err.getMessage()
            }
          }
        }   
      }  

  }

  post {
    always {
      echo 'One way or another, I have finished'
      archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/**/*.apk', fingerprint: true
    }
    success {
      telegramSend("${JOB_NAME}...O Build ${BUILD_DISPLAY_NAME} - Esta ok !!!\n Consulte o log para detalhes -> [Job logs](${env.BUILD_URL}console)\n\n Uma nova versão da aplicação esta disponivel!!!")
    }
    unstable {
      telegramSend("O Build ${BUILD_DISPLAY_NAME} <${env.BUILD_URL}> - Esta instavel ...\nConsulte o log para detalhes -> [Job logs](${env.BUILD_URL}console)")
    }
    failure {
      telegramSend("${JOB_NAME}...O Build ${BUILD_DISPLAY_NAME}  - Quebrou. \nConsulte o log para detalhes -> [Job logs](${env.BUILD_URL}console)")
    }
    changed {
      echo 'Things were different before...'
    }
    aborted {
      telegramSend("O Build ${BUILD_DISPLAY_NAME} - Foi abortado.\nConsulte o log para detalhes -> [Job logs](${env.BUILD_URL}console)")
    }
  }
}
