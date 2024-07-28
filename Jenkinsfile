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
    - 1h
  - name: docker
    image: docker:27-dind
    imagePullPolicy: Always
    securityContext:
      privileged: true
'''
		}
	}

	parameters {
		string(name: 'BRANCH', defaultValue: params.BRANCH ?: 'main', description: 'Branch to checkout')
		string(name: 'VERSION', defaultValue: params.APP_VERSION ?: '1.0', description: 'Major and minor version of the application')
	}

	environment { 
		APP_NAME = 'topfilms-keywind'
		APP_VERSION = "${params.VERSION}.${env.BUILD_NUMBER}"
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
					sh "npm version ${env.APP_VERSION} --no-git-tag-version"
					sh 'npm install'
					sh 'npm run build'
					sh 'npm run build:jar'
					sh 'cd out && unzip keywind.jar'

					sh 'ls -lah'
					sh 'ls ./out -lah'
				}
			}
		}

		stage('Docker Push Artifact') {
			steps {
				container('docker') {
					script {
						withCredentials([usernamePassword(credentialsId: '9bbf8bb7-1489-4260-a7a0-afce14eea51b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
							sh "echo '$DOCKER_PASSWORD' | docker login -u '$DOCKER_USERNAME' --password-stdin"
							sh "docker buildx build --platform linux/arm64/v8 . -t $DOCKER_USERNAME/$APP_NAME:$APP_VERSION"
							sh "docker push $DOCKER_USERNAME/$APP_NAME:$APP_VERSION"
						}
					}
				}
			}
		}

		// stage('Deploy Keycloak with Keywind') {
		// 	when {
		// 		expression { 
		// 			DEPLOY_KEYCLOAK == true
		// 		}
		// 	}
		// 	steps {
		// 		container('docker') {
		// 			script {
		// 				withCredentials([usernamePassword(credentialsId: '9bbf8bb7-1489-4260-a7a0-afce14eea51b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
		// 					sh 'ls -lah'
		// 					sh "echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin"
		// 					sh "docker buildx build --platform linux/arm64/v8 . -t $DOCKER_USERNAME/$ORG_NAME-$APP_NAME:$APP_VERSION"
		// 					sh "docker push $DOCKER_USERNAME/$ORG_NAME-$APP_NAME:$APP_VERSION"
		// 				}
		// 			}
		// 		}
		// 	}
		// }

	}
}