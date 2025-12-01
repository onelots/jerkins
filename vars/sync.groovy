def call(Map config = [:]) {

    def folderName  = ''
    def folderParts = []
    def evoVersion  = ''

    pipeline {
        agent any

        environment {
            SHORT_JOB_NAME = ''
        }

        stages {

            stage('Get Folder Name') {
                steps {
                    withCredentials([
                        string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')
                    ]) {
                        script {
                            folderName  = pwd().split('/')[-2]
                            folderParts = folderName.split(' - ')
                            evoVersion  = folderParts[0].split('\\.')[0]

                            echo "Evo Version : ${evoVersion}"
                        }
                    }
                }
            }

            stage('Initialize EvolutionX') {
                steps {
                    withCredentials([
                        string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')
                    ]) {
                        script {
                            dir("/media/sauces/evo${evoVersion}") {
                                sh "/media/sauces/scripts/shell/init.sh ${evoVersion}"
                            }
                        }
                    }
                }
            }
        }

        post {

            success {
                withCredentials([
                    string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')
                ]) {
                    script {
                        discordSend(
                            description: "Build environment initialize/updated !",
                            footer: 'Jenkins Pipeline',
                            link: env.BUILD_URL,
                            result: currentBuild.currentResult,
                            title: JOB_NAME,
                            webhookURL: DISCORD_WEBHOOK
                        )
                    }
                }
            }

            failure {
                withCredentials([
                    string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')
                ]) {
                    discordSend(
                        description: "Build environment initialization/update failed.",
                        footer: 'Jenkins Pipeline',
                        link: env.BUILD_URL,
                        result: currentBuild.currentResult,
                        title: JOB_NAME,
                        webhookURL: DISCORD_WEBHOOK
                    )
                }
            }
        }
    }
}
