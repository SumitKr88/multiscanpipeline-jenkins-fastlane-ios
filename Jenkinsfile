import groovy.util.*

// Powered by Infostretch
pipeline {
    agent { label 'mac-mini-slave-local' }

    parameters {
        // the default choice for commit-triggered builds is the first item in the choices list
        choice(name: 'buildVariant', choices: ['Debug_Scan_Only', 'Debug_TestFlight', 'Release_AppStore_TestFlight'], description: 'The variants to build')
        booleanParam(name: 'Push_To_Remote', defaultValue: false, description: 'Toggle to push changes back to remote(check for repo permission on this)')
    }
    environment {

        // Fastlane Environment Variables, in order to make fastlane in PATH with rvm
        PATH =  "$HOME/.fastlane/bin:" +
                "$HOME/.rvm/gems/ruby-2.6.3/bin:" +
                "$HOME/.rvm/gems/ruby-2.6.3@global/bin:" +
                "$HOME/.rvm/rubies/ruby-2.6.3/bin:" +
                "/usr/local/bin:" +
                "$PATH"
       
        LC_ALL = 'en_US.UTF-8'
        LANG = 'en_US.UTF-8'
        LANGUAGE = 'en_US.UTF-8'

        APP_NAME = 'AdManagerTest'
        BUILD_NAME = 'AdManagerTest'
        
        APP_TARGET = 'AdManagerTest'
        APP_SCHEME = 'AdManagerTest'
        APP_PROJECT = 'AdManagerTest.xcodeproj'
        APP_WORKSPACE = 'AdManagerTest.xcworkspace'
        APP_TEST_SCHEME = 'AdManagerTest'

	APP_BUILD_CONFIG = 'Release'
	APP_EXPORT_METHOD = 'app-store'
	APP_COMPILE_BITCODE = false
	GROUPS = 'Distribution group name'
	APP_DISTRIBUTION = 'testflight'
	APP_PROVISIONING_PROFILE = 'Test Flight test Profile'
	APP_CODESIGN_CERTIFICATE = 'iPhone Distribution: Multibranch Sample XV86347CF' 
        
        APP_STATIC_CODE_ANALYZER_REPORT = true
        APP_COVERAGE_REPORT = true

        BRANCH_NAME = 'Release/multibranchpipeline_ios'
        APP_CLEAN_BUILD = false
        PUBLISH_TO_CHANNEL = 'teams'
    }

    options {
        skipDefaultCheckout(true)
    }

    stages {
        
        //<< Git SCM Checkout >>
        stage('Git Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Update Env with Build Variant') {
            steps {
                script {
                    env.BUILD_VARIANT = params.buildVariant
                    // Conditionally define a build variant 'impact'
                    if (BUILD_VARIANT == 'Debug_TestFlight') {
                        echo "Debug_TestFlight"
                    } else if (BUILD_VARIANT == 'Release_AppStore_TestFlight') {
                        echo "Release_AppStore_TestFlight"
                    } else {
                       echo "Else block!!"
                    }
                }
            }
        }

        stage('Dot Files Check') {
            steps {
                script {
                    sh "if [ -e .gitignore ]; then echo '.gitignore found'; else echo 'no .gitignore found' && exit 1; fi"
                }
            }
        }

        stage('Git - Fetch Version/Commits') {
            steps {
                script {
                    env.GIT_COMMIT_MSG = sh(returnStdout: true, script: '''
                    git log -1 --pretty=%B ${GIT_COMMIT}
                    ''').trim()

                    env.BUILD_NUMBER_XCODE = sh(returnStdout: true, script: '''
                    echo $(xcodebuild -target "${APP_TARGET}" -configuration "${APP_BUILD_CONFIG}" -showBuildSettings  | grep -i 'CURRENT_PROJECT_VERSION' | sed 's/[ ]*CURRENT_PROJECT_VERSION = //')
                    ''').trim()

                    env.BUNDLE_SHORT_VERSION = sh(returnStdout: true, script: '''
                    echo $(xcodebuild -target "${APP_TARGET}" -configuration "${APP_BUILD_CONFIG}" -showBuildSettings  | grep -i 'MARKETING_VERSION' | sed 's/[ ]*MARKETING_VERSION = //')
                    ''').trim()

                    env.APP_BUNDLE_IDENTIFIER = sh(returnStdout: true, script: '''
                    echo $(xcodebuild -target "${APP_TARGET}" -configuration "${APP_BUILD_CONFIG}" -showBuildSettings  | grep -i 'PRODUCT_BUNDLE_IDENTIFIER' | sed 's/[ ]*PRODUCT_BUNDLE_IDENTIFIER = //')
                    ''').trim()

                    def DATE_TIME = sh(returnStdout: true, script: '''
                    date +%Y.%m.%d-%H:%M:%S
                    ''').trim()

                    env.APP_BUILD_NAME = "${env.APP_NAME}-${env.BUILD_NUMBER}-Ver-${env.BUNDLE_SHORT_VERSION}-B-${env.BUILD_NUMBER_XCODE}-${DATE_TIME}"
                    echo "Build Name: ${env.APP_BUILD_NAME}"

                    env.GIT_BRANCH = sh(returnStdout: true, script: '''
                    git name-rev --name-only HEAD
                    ''').trim()
                    echo "Branch name: ${env.BRANCH_NAME}"
                    echo "Current Branch: ${env.GIT_BRANCH}"
                }
            }
        }

        stage('Unit Test cases') {
                    steps {
                        script {
                                try {
                                    sh """
                                    #!/bin/bash
                                    echo "Executing Fastlane test lane..."
                                    ${ env.FASTLANE } tests
                                    """
                                } catch(exc) {
                                    currentBuild.result = "UNSTABLE"
                                    error('There are failed tests.')
                                }
                            }
                        }
                    post {
                            always {
                                junit(testResults: '**/reports/report.junit', allowEmptyResults: true)
                            }
                        }
        }
        
        stage('Quality checks - Report') {
            parallel {
                stage('Linting') {
                    when {
                        expression { env.APP_STATIC_CODE_ANALYZER_REPORT == 'true' }
                    }
                    steps {
                        script {
                                sh """
                                #!/bin/bash
                                echo "Executing Fastlane Linting lane..."
                                ${ env.FASTLANE } lint
                                """
                            }
                        }
                            post {
                                always {
                                    script {
                                            // find and publish lint results
                                            def checkStyleIssues = scanForIssues tool: checkStyle(pattern: '**/reports/swiftlint.xml')
                                            publishIssues issues: [checkStyleIssues]
                                        }
                                }
                            }
                    }

                    stage('Code Coverage') {
                        when {
                            expression { env.APP_COVERAGE_REPORT == 'true' }
                        }
                        steps {
                            script {
                                sh """
                                #!/bin/bash
                                echo "Executing Fastlane Code Coverage lane..."
                                ${ env.FASTLANE } code_coverage
                                """
                            }
                        }
                        post {
                            success {
                                //step([$class: 'CoberturaPublisher', coberturaReportFile: '**/reports/cobertura.xml', autoUpdateHealth: false, autoUpdateStability: false,failUnhealthy: false, failUnstable: false, maxNumberOfBuilds: 0, onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false])
                                cobertura coberturaReportFile: '**/reports/cobertura.xml', enableNewApi: true
                            }
                        }
                    }
            }
        }

        stage('Commit File changes') {
            steps {
                sh """
                #!/bin/bash
                echo "Comitting the file changes..."
                git add -A && git commit -m "Updated testcase reports"
                """
            }
        }

        stage('Building') {
            // Shell build step
            steps {
                script {
                    if (env.BUILD_VARIANT == 'Debug_Scan_Only') {
                        stage ('Scan - Build Only') {
                            sh "xcodebuild -workspace ${env.APP_WORKSPACE} -scheme ${env.APP_SCHEME} -sdk iphoneos -configuration \"${env.APP_BUILD_CONFIG}\" CODE_SIGN_IDENTITY=\"\" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS=\"\" CODE_SIGNING_ALLOWED=\"NO\" build"
                        }
                    } else {
                        stage ('Distribute - Build & Archive') {
                            sh """
                            #!/bin/bash
                            echo "Executing Fastlane build lane to build..."
                            ${ env.FASTLANE } build app_build_name:${env.APP_BUILD_NAME}
                            """
                        }
                    }
                }
            }
        }

        stage('Generating Package') {
            when {
                // don't push PR branches to App Distribution
                expression { (env.BRANCH_NAME == 'master' || env.BRANCH_NAME.startsWith("Release/")) && env.BUILD_VARIANT != 'Debug_Scan_Only'}
            }
            // Shell build step
            steps {
                script {

                    //If custom message to be send as part of release notes, modify the release_notes.txt
                    //Add your custome message in release_notes.txt under "Current Build Changes"
                    env.RELEASE_NOTES_TXT = "release_notes/release_notes.txt"
                    sh 'perl -i -pe "s/%APP_BUILD_NAME%/${APP_BUILD_NAME}/g; s/BUILD_ID/$(git rev-parse --short HEAD)/g" $RELEASE_NOTES_TXT'

                    env.RELEASE_NOTES = sh(returnStdout: true, script: '''
                    cat ${RELEASE_NOTES_TXT}
                    ''').trim()
                }

                sh """
                #!/bin/bash
                echo "Executing Fastlane upload lane to start uploading executables..."
                ${ env.FASTLANE } upload app_build_name:${env.APP_BUILD_NAME}
                """
            }
        }

        stage('Post Build -- Actions') {
            when {
                // don't push PR branches to App Distribution
                expression { (env.BRANCH_NAME == 'master' || env.BRANCH_NAME.startsWith("Release/")) && env.BUILD_VARIANT != 'Debug_Scan_Only'}
            }
            parallel {
                stage('Pushing build to remote') {
                    when {
                        // don't push PR branches to App Distribution
                        expression { params.Push_To_Remote }
                    }
                    // Shell build step
                    steps {
                        script {
                                try {
                                    sh """
                                    #!/bin/bash
                                    echo "Executing Fastlane lane push changes to remote..."
                                    ${ env.FASTLANE } push_to_remote
                                    """
                                } catch(exc) {
                                    currentBuild.result = "UNSTABLE"
                                    error('Not able push the changes to remote.')
                                }
                            }
                    }
                }

                stage('Archive Artifacts') {
                    steps {
                        //Archive the artifacts
                        archiveArtifacts '**/*.ipa, **/*.zip'
                    }
                }

            }
        }

    }

    post {
        success {
            office365ConnectorSend color: '#86BC25', status: currentBuild.result, webhookUrl: "${ env.WEBHOOK_URL }",
            message: "Successfully Build: ${JOB_NAME} - ${currentBuild.displayName}<br>Pipeline duration: ${currentBuild.durationString.replace(' and counting', '')}",
            factDefinitions: [[name: "Build Name:", template: "${env.APP_BUILD_NAME}"],
                              [name: "App Version:", template: "${env.BUNDLE_SHORT_VERSION}(${env.BUILD_NUMBER_XCODE})"],
                              [name: "Last Commit", template: "${env.GIT_COMMIT_MSG}"]]
        }

        unstable {
            office365ConnectorSend color: '#FFE933', status: currentBuild.result, webhookUrl: "${ env.WEBHOOK_URL }",
            message: "Successfully Build but Unstable. Unstable means test failure, code violation, push to remote failed etc. : ${JOB_NAME} - ${currentBuild.displayName}<br>Pipeline duration: ${currentBuild.durationString.replace(' and counting', '')}",
            factDefinitions: [[name: "Build Name:", template: "${env.APP_BUILD_NAME}"],
                              [name: "App Version:", template: "${env.BUNDLE_SHORT_VERSION}(${env.BUILD_NUMBER_XCODE})"],
                              [name: "Last Commit", template: "${env.GIT_COMMIT_MSG}"]]
        }

        failure {
            office365ConnectorSend color: '#ff0000', status: currentBuild.result, webhookUrl: "${ env.WEBHOOK_URL }",
            message: "Build Failed: ${JOB_NAME} - ${currentBuild.displayName}<br>Pipeline duration: ${currentBuild.durationString.replace(' and counting', '')}",
            factDefinitions: [[name: "Build Name:", template: "${env.APP_BUILD_NAME}"],
                              [name: "App Version:", template: "${env.BUNDLE_SHORT_VERSION}(${env.BUILD_NUMBER_XCODE})"],
                              [name: "Last Commit", template: "${env.GIT_COMMIT_MSG}"]]
        }

        always {
            echo "Build completed with status: ${currentBuild.result}"
        }
    }
}
