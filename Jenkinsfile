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
		string(name: 'KEYWIND_VERSION', defaultValue: params.KEYWIND_VERSION ?: '1.0', description: 'Major and minor version of the application')
		booleanParam(name: 'DEPLOY_KEYCLOAK', defaultValue: "false", description: 'Deploy Keycloak with new Keywind theme')
		string(name: 'KEYCLOAK_VERSION', defaultValue: '23.0.7', description: 'Full version of keycloak')
		string(name: 'K8S_BRANCH', defaultValue: params.K8S_BRANCH ?: 'main', description: 'Branch to checkout in k8s repo')
	}

	environment { 
		KEYWIND_NAME = 'topfilms-keywind'
		KEYWIND_VERSION_FULL = "${params.KEYWIND_VERSION}.${env.BUILD_NUMBER}"
		KEYWIND_GITHUB_URL = 'https://github.com/Top-Films/topfilms-keywind'

		DOCKER_REGISTRY = 'registry-1.docker.io'
		DOCKER_REGISTRY_FULL = "oci://${env.DOCKER_REGISTRY}"

		K8S_GITHUB_URL = 'https://github.com/Top-Films/k8s'
		
		KEYCLOAK_NAME = 'keycloak'
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
					sh "npm version ${env.KEYWIND_VERSION_FULL} --no-git-tag-version"

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

							sh 'docker buildx build --platform linux/arm64/v8 . -t $DOCKER_USERNAME/$KEYWIND_NAME:$KEYWIND_VERSION_FULL -t $DOCKER_USERNAME/$KEYWIND_NAME:latest'
							sh 'docker push $DOCKER_USERNAME/$KEYWIND_NAME -a'
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

		stage('Keycloak File Substitutions with Secrets') {
			when {
				expression { 
					DEPLOY_KEYCLOAK == "true"
				}
			}
			steps {
				script {
					dir("${WORKSPACE}/k8s") {
						withCredentials([
							usernamePassword(credentialsId: 'keycloak-admin', usernameVariable: 'KEYCLOAK_ADMIN_USERNAME', passwordVariable: 'KEYCLOAK_ADMIN_PASSWORD'),
							usernamePassword(credentialsId: 'keycloak-db', usernameVariable: 'KEYCLOAK_DB_USERNAME', passwordVariable: 'KEYCLOAK_DB_PASSWORD'),
							string(credentialsId: 'keycloak-db-host', variable: 'KEYCLOAK_DB_HOST'),
							file(credentialsId: 'keycloak-cert', variable: 'KEYCLOAK_CERT'),
							file(credentialsId: 'keycloak-cert-private-key', variable: 'KEYCLOAK_CERT_PRIVATE_KEY'),
							file(credentialsId: 'kube-config', variable: 'KUBE_CONFIG')
						]) {
							sh 'mkdir -p $WORKSPACE/.kube && cp $KUBE_CONFIG $WORKSPACE/.kube/config'

							sh """
								cd $KEYCLOAK_NAME

								KEYCLOAK_ADMIN_USERNAME_B64=(echo $KEYCLOAK_ADMIN_USERNAME | base64)
								KEYCLOAK_ADMIN_PASSWORD_B64=(echo $KEYCLOAK_ADMIN_PASSWORD | base64)
								KEYCLOAK_DB_USERNAME_B64=(echo $KEYCLOAK_DB_USERNAME | base64)
								KEYCLOAK_DB_PASSWORD_B64=(echo $KEYCLOAK_DB_PASSWORD | base64)
								KEYCLOAK_DB_HOST_B64=(echo $KEYCLOAK_DB_HOST | base64)
								KEYCLOAK_CERT_B64=(echo $KEYCLOAK_CERT | base64)
								KEYCLOAK_CERT_PRIVATE_KEY_B64=(echo $EYCLOAK_CERT_PRIVATE_KEY | base64)

								sed -i "s/<KEYCLOAK_ADMIN_USERNAME>/$KEYCLOAK_ADMIN_USERNAME_B64/g" secret.yaml
								sed -i "s/<KEYCLOAK_ADMIN_PASSWORD>/$KEYCLOAK_ADMIN_PASSWORD_B64/g" secret.yaml
								sed -i "s/<KEYCLOAK_DB_USERNAME>/$KEYCLOAK_DB_USERNAME_B64/g" secret.yaml
								sed -i "s/<KEYCLOAK_DB_PASSWORD>/$KEYCLOAK_DB_PASSWORD_B64/g" secret.yaml
								sed -i "s/<KEYCLOAK_DB_HOST>/$KEYCLOAK_DB_HOST_B64/g" secret.yaml
								sed -i "s/<KEYCLOAK_CERT>/$KEYCLOAK_CERT_B64/g" secret.yaml
								sed -i "s/<KEYCLOAK_CERT_PRIVATE_KEY>/$KEYCLOAK_CERT_PRIVATE_KEY_B64/g" secret.yaml
							"""

							sh """
								cd $KEYCLOAK_NAME

								kubectl apply -f secret.yaml
							"""
						}
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
								cd $KEYCLOAK_NAME

								echo "$DOCKER_PASSWORD" | helm registry login $DOCKER_REGISTRY --username $DOCKER_USERNAME --password-stdin

								helm package helm --app-version=$KEYCLOAK_VERSION_HELM --version=$KEYCLOAK_VERSION_HELM
								helm push ./$KEYCLOAK_NAME-$KEYCLOAK_VERSION_HELM.tgz $DOCKER_REGISTRY_FULL/$DOCKER_USERNAME
							'''
						}
					}
				}
			}
		}

		stage('Deploy Keycloak') {
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
						sh 'mkdir -p $WORKSPACE/.kube && cp $KUBE_CONFIG $WORKSPACE/.kube/config'

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