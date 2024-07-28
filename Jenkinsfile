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
  - name: dind
    image: docker:27.1.1-dind-alpine3.20
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - 99d

'''
		}
	}

	parameters {
		string(name: 'BRANCH', defaultValue: params.BRANCH ?: 'main', description: 'Branch to checkout')
		string(name: 'APP_VERSION', defaultValue: params.APP_VERSION ?: '1.0.0', description: 'Version of the application')
	}

	environment { 
		ORG_NAME = 'topfilms'
		APP_NAME = 'topfilms-keywind'
		GITHUB_URL = 'https://github.com/Top-Films/topfilms-keywind'
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
					sh "npm version ${params.APP_VERSION} --no-git-tag-version"
					sh 'npm install'
					sh 'npm run build'
					sh 'npm run build:jar'
				}
			}
		}

		stage('Docker Push Artifact') {
			steps {
				container('dind') {
					script {
						withCredentials([usernamePassword(credentialsId: '9bbf8bb7-1489-4260-a7a0-afce14eea51b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
							sh "docker buildx build --platform linux/arm64/v8 . -t $DOCKER_USERNAME/$ORG_NAME-$APP_NAME:$APP_VERSION"
							sh "echo '$DOCKER_PASSWORD' | docker login -u '$DOCKER_USERNAME' --password-stdin"
							sh "docker push $DOCKER_USERNAME/$ORG_NAME-$APP_NAME:$APP_VERSION"
						}
					}
				}
			}
		}

	}
}