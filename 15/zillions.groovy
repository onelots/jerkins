pipeline {
    agent any

    environment {
        SHORT_JOB_NAME = ''
    }

    stages {
        stage('Sync device trees') {
            steps {
                dir('/media/sauces/evo10') {
                    sh '''
                    /media/sauces/scripts/15/03-reposync.sh \
                    ${JOB_BASE_NAME} \
                    device/ OEM /${JOB_BASE_NAME} \
                    vendor/ OEM /${JOB_BASE_NAME} \
                    kernel/ OEM /${JOB_BASE_NAME} \
                    hardware/ OEM
                    '''
                }
            }
        }
        stage('Build ROM') {
            steps {
                dir('/media/sauces/evo10') {
                    sh '''
                    /media/sauces/scripts/15/04-build.sh ${JOB_BASE_NAME}
                    '''
                    script {
                        def artifactPath1 = "out/target/product/${JOB_BASE_NAME}/${JOB_BASE_NAME}.json"
                        def artifactPath2 = "evolution/OTA/changelogs/${JOB_BASE_NAME}.txt"
                        
                        archiveArtifacts artifacts: "${artifactPath1},${artifactPath2}", allowEmptyArchive: true                    }
                }
            }
        }
        stage('Upload Artifacts') {
            steps {
                dir('/media/sauces/evo10') {
                    withCredentials([
                        sshUserPrivateKey(credentialsId: 'mirror_key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
                        string(credentialsId: 'mirror_user', variable: 'MIRROR_USER'),
                        string(credentialsId: 'mirror_host', variable: 'MIRROR_HOST')
                    ]) {
                    sh '''
                    /media/sauces/scripts/15/05-upload.sh ${JOB_BASE_NAME} ${MIRROR_USER} ${MIRROR_HOST} ${SSH_KEY}
                    '''
                    
                    script {
                        if (fileExists('/tmp/upload_link.txt')) {
                            def uploadLink = readFile('/tmp/upload_link.txt').trim()
                            env.UPLOAD_LINK = uploadLink
                            echo "Download link: ${env.UPLOAD_LINK}"
                        } else {
                            echo "File /tmp/upload_link.txt doesn't exist."
                            currentBuild.result = 'FAILURE'
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                env.JSONURL = "${env.BUILD_URL}artifact/out/target/product/${env.JOB_BASE_NAME}/${env.JOB_BASE_NAME}.json"
                env.TXTURL  = "${env.BUILD_URL}artifact/evolution/OTA/changelogs/${env.JOB_BASE_NAME}.txt"

                long ms = currentBuild.duration ?: (System.currentTimeMillis() - currentBuild.startTimeInMillis)
                int totalSec = (int)(ms / 1000)
                env.BUILD_MINUTES = (totalSec.intdiv(60)).toString()
                env.BUILD_SECONDS = (totalSec % 60).toString()

                if (fileExists('/tmp/upload_link.txt')) {
                    env.UPLOAD_LINK = readFile('/tmp/upload_link.txt').trim()
                    echo "Download link: ${env.UPLOAD_LINK}"
                } else {
                    env.UPLOAD_LINK = ''
                    echo "File /tmp/upload_link.txt doesn't exist."
                }
            }
        }

        success {
            dir('/media/sauces/evo10') {
                withCredentials([string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')]) {
                    sh '''
                        EVO_FILE=$(ls -t out/target/product/"$JOB_BASE_NAME"/EvolutionX-*.zip 2>/dev/null | head -n1 || true)
                        if [ -n "$EVO_FILE" ]; then
                            EVO_BASENAME=$(basename "$EVO_FILE")
                            # L’ancienne logique coupait au "-" et prenait le 5e champ
                            EVO_VERSION=$(echo "$EVO_BASENAME" | cut -d "-" -f 5)
                        else
                            EVO_VERSION="unknown"
                        fi

                        /media/sauces/scripts/15/05-webhook.sh \
                        --webhook-url "$DISCORD_WEBHOOK" \
                        --status success \
                        --device "$JOB_BASE_NAME" \
                        --minutes "$BUILD_MINUTES" \
                        --seconds "$BUILD_SECONDS" \
                        --starter "Onelots" \
                        --username "EvolutionX Jenkins - Vic" \
                        --rom-version "$EVO_VERSION" \
                        --build-format "installclean" \
                        --build-type "userdebug" \
                        --node "BORD-ONE-FR" \
                        --build-url "$UPLOAD_LINK" \
                        --txt-url "$TXTURL" \
                        --json-url "$JSONURL"
                    '''
                }
            }
        }

        failure {
            dir('/media/sauces/evo10') {
                withCredentials([string(credentialsId: 'discord-webhook', variable: 'DISCORD_WEBHOOK')]) {
                    sh '''
                        EVO_FILE=$(ls -t out/target/product/"$JOB_BASE_NAME"/EvolutionX-*.zip 2>/dev/null | head -n1 || true)
                        if [ -n "$EVO_FILE" ]; then
                            EVO_VERSION=$(basename "$EVO_FILE" | cut -d "-" -f 5)
                        else
                            EVO_VERSION="unknown"
                        fi

                        /media/sauces/scripts/15/05-webhook.sh \
                        --webhook-url "$DISCORD_WEBHOOK" \
                        --status failure \
                        --device "$JOB_BASE_NAME" \
                        --minutes "$BUILD_MINUTES" \
                        --seconds "$BUILD_SECONDS" \
                        --starter "Onelots" \
                        --username "EvolutionX Jenkins - Vic" \
                        --rom-version "$EVO_VERSION" \
                        --build-format "installclean" \
                        --build-type "userdebug" \
                        --node "BORD-ONE-FR" \
                        --build-url "$UPLOAD_LINK" \
                        --txt-url "$TXTURL" \
                        --json-url "$JSONURL"
                    '''
                }
            }
        }
    }
}