pipeline {
	agent {
		kubernetes {
			defaultContainer 'node'
			yaml '''
kind: Pod
spec:
  containers:
  - name: node
    image: node:22-alpine
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - 99d
  containers:
  - name: docker
    image: docker:cli
    imagePullPolicy: Always
    args:
    - "--privileged"
'''
		}
	}

	parameters {
		string(name: 'BRANCH', defaultValue: params.BRANCH ?: 'main', description: 'Branch to checkout')
		string(name: 'VERSION', defaultValue: params.APP_VERSION ?: '1.0', description: 'Major and minor version of the application')
	}

	environment { 
		ORG_NAME = 'topfilms'
		APP_NAME = 'topfilms-keywind'
		GITHUB_URL = 'https://github.com/Top-Films/topfilms-keywind'
		APP_VERSION = "${params.VERSION}.${env.BUILD_NUMBER}"
	}

	stages {

		stage('Git Clone') {
			steps {
				script {
					checkout scmGit(
						branches: [[
							name: "${params.BRANCH}"
						]],
						userRemoteConfigs: [[
							credentialsId: '827446b2-c8ac-4420-bcda-87696bb62634',
							url: "${env.GITHUB_URL}"
						]]
					)

					sh 'ls -lah'
					sh 'node -v'
				}
			}
		}

		stage('Node Build') {
			steps {
				script {
					sh "npm version ${env.APP_VERSION} --no-git-tag-version"
					sh 'npm install'
					sh 'npm run build'
					sh 'npm run build:jar'

					sh 'ls -lah'
					sh 'ls ./out -lah'
					sh 'ls ./theme -lah'
				}
			}
		}

		stage('Docker Push Artifact') {
			steps {
				container('docker') {
					script {
						withCredentials([usernamePassword(credentialsId: '9bbf8bb7-1489-4260-a7a0-afce14eea51b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
							docker.withRegistry('https://docker.io', '9bbf8bb7-1489-4260-a7a0-afce14eea51b') {
								docker.build("$DOCKER_USERNAME/$ORG_NAME-$APP_NAME:$APP_VERSION").push()
							}
						}
					}
				}
			}
		}

	}
}