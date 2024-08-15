pipeline {
	agent {
		kubernetes {
			defaultContainer 'buildpack'
			yaml '''
kind: Pod
spec:
  containers:
  - name: buildpack
    image: maxmorhardt/topfilms-jenkins-buildpack:latest
    imagePullPolicy: Always
    securityContext:
      privileged: true
  - name: dind
    image: docker:27-dind
    imagePullPolicy: Always
    securityContext:
      privileged: true
'''
		}
	}

	parameters {
		string(name: 'KEYWIND_BRANCH', defaultValue: params.KEYWIND_BRANCH ?: 'main', description: 'Branch to checkout in keywind repo')
		string(name: 'VERSION', defaultValue: params.APP_VERSION ?: '1.0', description: 'Major and minor version of the application')
		booleanParam(name: 'DEPLOY_KEYCLOAK', defaultValue: "false", description: 'Deploy Keycloak with new Keywind theme')
		string(name: 'K8S_BRANCH', defaultValue: params.K8S_BRANCH ?: 'main', description: 'Branch to checkout in k8s repo')
	}

	environment { 
		APP_NAME = 'topfilms-keywind'
		APP_VERSION = "${params.VERSION}.${env.BUILD_NUMBER}"
		KEYWIND_GITHUB_URL = 'https://github.com/Top-Films/topfilms-keywind'
		K8S_GITHUB_URL = 'https://github.com/Top-Films/k8s'
		DOCKER_REGISTRY = 'registry-1.docker.io'
		DOCKER_REGISTRY_FULL = "oci://${env.DOCKER_REGISTRY}"
		KEYCLOAK_NAME = 'keycloak'
		KEYCLOAK_VERSION = "23.0.7"
		KEYCLOAK_VERSION_HELM = "${env.KEYCLOAK_VERSION}-${env.BUILD_NUMBER}"
	}

	stages {

		stage('Git Clone Keywind') {
			steps {
				script {
					checkout scmGit(
						branches: [[
							name: "${params.KEYWIND_BRANCH}"
						]],
						userRemoteConfigs: [[
							credentialsId: 'github',
							url: "${env.KEYWIND_GITHUB_URL}"
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
				container('dind') {
					script {
						withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
							sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
							sh 'docker buildx build --platform linux/arm64/v8 . -t $DOCKER_USERNAME/$APP_NAME:$APP_VERSION -t $DOCKER_USERNAME/$APP_NAME:latest'
							sh 'docker push $DOCKER_USERNAME/$APP_NAME:$APP_VERSION'
						}
					}
				}
			}
		}

		stage('Git Clone K8s') {
			when {
				expression { 
					DEPLOY_KEYCLOAK == "true"
				}
			}
			steps {
				script {
					dir("${WORKSPACE}/k8s") {
						checkout scmGit(
							branches: [[
								name: "${params.K8S_BRANCH}"
							]],
							userRemoteConfigs: [[
								credentialsId: 'github',
								url: "${env.K8S_GITHUB_URL}"
							]]
						)

						sh 'ls -lah'
					}
				}
			}
		}

		stage('Build Keycloak') {
			when {
				expression { 
					DEPLOY_KEYCLOAK == "true"
				}
			}
			steps {
				script {
					dir("${WORKSPACE}/k8s") {
						withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
							sh '''
								cd keycloak
								echo "$DOCKER_PASSWORD" | helm registry login $DOCKER_REGISTRY --username $DOCKER_USERNAME --password-stdin
								helm package helm --app-version=$KEYCLOAK_VERSION_HELM --version=$KEYCLOAK_VERSION_HELM
								helm push ./$KEYCLOAK_NAME-$KEYCLOAK_VERSION_HELM.tgz $DOCKER_REGISTRY_FULL/$DOCKER_USERNAME
							'''
						}
					}
				}
			}
		}

		stage('Deploy Keycloak with Keywind') {
			when {
				expression { 
					DEPLOY_KEYCLOAK == "true"
				}
			}
			steps {
				script {
					withCredentials([
						usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'), 
						file(credentialsId: 'kube-config', variable: 'KUBE_CONFIG')
					]) {
						sh 'mkdir -p $WORKSPACE/.kube && cp $KUBE_CONFIG ${WORKSPACE}/.kube/config'

						sh '''
							echo "$DOCKER_PASSWORD" | helm registry login $DOCKER_REGISTRY --username $DOCKER_USERNAME --password-stdin
							helm upgrade $KEYCLOAK_NAME $DOCKER_REGISTRY_FULL/$DOCKER_USERNAME/$KEYCLOAK_NAME --version $KEYCLOAK_VERSION_HELM --install --atomic --debug --history-max=3 --namespace keycloak --set image.tag=$KEYCLOAK_VERSION
						'''
					}
				}
			}
		}

	}
}