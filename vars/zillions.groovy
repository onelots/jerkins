def call(Map config = [:]) {
    def jobName = config.jobName ?: env.JOB_BASE_NAME
    
    def folderName = ''
    def folderParts = []
    def evoVersion = ''
    def buildType = ''
    def sourceDir = ''

    pipeline {
        agent any

        environment {
            SHORT_JOB_NAME = ''
        }

        stages {
            stage('Get Folder Name & Define Base Paths') {
                steps {
                    script {
                        folderName = pwd().split('/')[-2]

                        folderParts = folderName.split(' - ')

                        evoVersion = folderParts[0].split('\\.')[0]
                        buildType = folderParts[2].toLowerCase()

                        echo "Parent Folder : ${folderName}"
                        echo "Evo Version   : ${evoVersion}"
                        echo "Build Type    : ${buildType}"

                        sourceDir = "/media/sauces/evo${evoVersion}"
                    }
                }
            }
            stage('Get necessary scripts') { // Allow us to NOT ALWAYS MANUALLY UPDATE THE SCRIPTS RHAAAA
                steps {
                    dir("/media/sauces") {
                        sh '''
                        REPO_URL="https://github.com/onelots/jerkins"
                        DIR="scripts"

                        if [ ! -d "$DIR/.git" ]; then
                            git clone --depth 1 -b main "$REPO_URL" "$DIR"
                        else
                            cd "$DIR"
                            git fetch origin main
                            git reset --hard origin/main
                            git clean -ffd
                        fi

                        echo " "
                        echo " "
                        echo "-----------------------------------------------------"
                        echo "Scripts are up to date !"
                        echo "-----------------------------------------------------"
                        '''
                    }
                }
            }
            stage('Nuke necessary repos') { // Sometimes, a device messes up with an other. To avoid the hassle of rewriting, some parts, let's just nuke the said device... Anyway it's not that painful
                steps {
                    dir(sourceDir) {
                        sh '''
                        /media/sauces/scripts/shell/reponuke.sh ${JOB_BASE_NAME}
                        '''
                    }
                }
            }
            stage('Sync device trees') {
                steps {
                    dir(sourceDir) {
                        withEnv(["EVO_VERSION=${evoVersion}"]) {
                        sh '''
                        if [ "$EVO_VERSION" = "10" ]; then
                            VERSION="vic"
                        elif [ "$EVO_VERSION" = "11" ]; then
                            VERSION="bka"
                        fi
                        /media/sauces/scripts/shell/sync-device.sh ${JOB_BASE_NAME} "$VERSION"
                        '''
                        }
                    }
                }
            }
            stage('Build ROM') {
                steps {
                    dir(sourceDir) {
                        sh '''
                        /media/sauces/scripts/shell/build.sh ${JOB_BASE_NAME}
                        '''
                        script {
                            def artifactPath1 = "out/target/product/${JOB_BASE_NAME}/${JOB_BASE_NAME}.json"
                            def artifactPath2 = "evolution/OTA/changelogs/${JOB_BASE_NAME}.txt"
                        
                            archiveArtifacts artifacts: "${artifactPath1},${artifactPath2}", allowEmptyArchive: true                    
                        }
                    }
                }
            }
            stage('Upload Artifacts') {
                steps {
                    dir(sourceDir) {
                        withEnv(["BUILD_TYPE=${buildType}"]) {
                            sh '''
                                set -e
                                rm -f /tmp/upload_link.txt
                                /media/sauces/scripts/shell/upload.sh "$JOB_BASE_NAME" "$BUILD_TYPE"
                                '''
                            }
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
                dir(sourceDir) {
                    withCredentials([
                        string(credentialsId: 'discord-webhook',        variable: 'DISCORD_WEBHOOK'),
                        string(credentialsId: 'webhook-evo',         variable: 'EVO_DISCORD_WEBHOOK')
                            ]) {
                        withEnv(["BUILD_TYPE=${buildType}"]) {
                            sh '''
                            if [ "$BUILD_TYPE" = "release" ]; then
                                WEBHOOK="$EVO_DISCORD_WEBHOOK"
                            else
                                WEBHOOK="$DISCORD_WEBHOOK"
                            fi

                            /media/sauces/scripts/shell/webhook.sh \
                            --webhook-url "$WEBHOOK" \
                            --status success \
                            --device "$JOB_BASE_NAME" \
                            --time "**$BUILD_MINUTES** minutes and **$BUILD_SECONDS** seconds" \
                            --starter "Onelots" \
                            --build-format "installclean" \
                            --build-type "userdebug" \
                            --build-url "$UPLOAD_LINK" \
                            --txt-url "$TXTURL" \
                            --json-url "$JSONURL"
                        '''
                        }
                    }
                }
            }

            failure {
                dir(sourceDir) {
                    withCredentials([
                        string(credentialsId: 'discord-webhook',        variable: 'DISCORD_WEBHOOK'),
                        string(credentialsId: 'webhook-evo',         variable: 'EVO_DISCORD_WEBHOOK')
                            ]) {
                        withEnv(["BUILD_TYPE=${buildType}"]) {
                            sh '''
                            if [ "$BUILD_TYPE" = "release" ]; then
                                WEBHOOK="$EVO_DISCORD_WEBHOOK"
                            else
                                WEBHOOK="$DISCORD_WEBHOOK"
                            fi

                            /media/sauces/scripts/shell/webhook.sh \
                            --webhook-url "$WEBHOOK" \
                            --status failed \
                            --device "$JOB_BASE_NAME" \
                            --time "**$BUILD_MINUTES** minutes and **$BUILD_SECONDS** seconds" \
                            --starter "Onelots" \
                            --build-format "installclean" \
                            --build-type "userdebug" \
                            --build-url "$UPLOAD_LINK" \
                            --txt-url "$TXTURL" \
                            --json-url "$JSONURL"
                        '''
                        }
                    }
                }
            }
        }
    }
}