def call(Map config = [:]) {
    
    pipeline {
    agent any

    environment {
        SHORT_JOB_NAME = ''
    }

    stages {
        stage('Get Folder Name') {
            steps {
                script {
                    folderName = pwd().split('/')[-2]
                    folderParts = folderName.split(' - ')

                    evoVersion = folderParts[0].split('\\.')[0]
                    echo "Evo Version   : ${evoVersion}"
                }
            }
        }

        stage('Initialize EvolutionX 10.X') {
            steps {
                dir('/media/sauces/evo10') {
                    withEnv(["evoVersion=${evoVersion}"]) {
                        sh '''
                        /media/sauces/scripts/shell/init.sh ${evoVersion}
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                discordSend description: "Build environment initialize/updated !",
                    footer: 'Jenkins Pipeline', 
                    link: env.BUILD_URL, 
                    result: currentBuild.currentResult, 
                    title: JOB_NAME, 
                    webhookURL: 'https://discord.com/api/webhooks/1383563100644446320/nS6YIzsrgiQyIMdJXFXjecCYGuIntArpQzLjCAOy9ctT35YXH67SrKwxKgu1RfpPEeAH'
            }
        }
        failure {
            discordSend description: "Build environment initialization/update failed.",
                footer: 'Jenkins Pipeline', 
                link: env.BUILD_URL, 
                result: currentBuild.currentResult, 
                title: JOB_NAME, 
                webhookURL: 'https://discord.com/api/webhooks/1383563100644446320/nS6YIzsrgiQyIMdJXFXjecCYGuIntArpQzLjCAOy9ctT35YXH67SrKwxKgu1RfpPEeAH'
            }
        }
    }
}
