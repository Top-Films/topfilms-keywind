podTemplate(
	containers: [
		containerTemplate(name: 'maven', image: 'maven:latest', command: 'sleep', args: '99d')
  	]
) {

    node(POD_LABEL) {
		stage('Maven') {
            container('maven') {

				

                stage('Git Clone') {
                    checkout scmGit(
						branches: [[name: 'main']],
						userRemoteConfigs: [
							[
								credentialsId: '827446b2-c8ac-4420-bcda-87696bb62634',
								url: 'https://github.com/Top-Films/topfilms-keywind'
							]
						]
					)

					sh 'ls -lah'
					sh 'mvn --version'
                }



            }
		}
    }
}