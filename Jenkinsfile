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
		KEYCLOAK_NAME = 'keycloak'
		KEYCLOAK_VERSION = '23.0.7'
	}

	stages {

		stage('Git Clone') {
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
							sh 'docker buildx build --platform linux/arm64/v8 . -t $DOCKER_USERNAME/$APP_NAME:$APP_VERSION'
							sh 'docker push $DOCKER_USERNAME/$APP_NAME:$APP_VERSION'
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
					dir("${WORKSPACE}/k8s") {
						withKubeConfig([credentialsId: 'kube-config']) {
							checkout scmGit(
								branches: [[
									name: "${params.K8S_BRANCH}"
								]],
								userRemoteConfigs: [[
									credentialsId: 'github',
									url: "${env.K8S_GITHUB_URL}"
								]]
							)
							
							sh '''
								cd keycloak
								echo "$DOCKER_PASSWORD" | helm registry login registry-1.docker.io --username $DOCKER_USERNAME --password-stdin
								helm package helm --app-version=$KEYCLOAK_VERSION --version=$KEYCLOAK_VERSION
								helm push ./$KEYCLOAK_NAME-$KEYCLOAK_VERSION.tgz oci://registry-1.docker.io/$DOCKER_USERNAME
								helm upgrade $KEYCLOAK_NAME ./$KEYCLOAK_NAME-$KEYCLOAK_VERSION.tgz --install --atomic --debug --history-max=3 -n topfilms --set image.tag=$KEYCLOAK_VERSION
							'''
						}
					}
				}
			}
		}

	}
}