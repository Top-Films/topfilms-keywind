pipeline {
    agent { docker { image 'atools/jdk-maven-node' } }
    stages {
        stage('build') {
            steps {
				sh 'ls -lah'
                sh ''
            }
        }

		stage('push artifact') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}