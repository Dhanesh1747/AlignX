pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout Code') {
            steps {
                // Public repository; use a Jenkins credential if the repository becomes private.
                git branch: 'main', url: 'https://github.com/Dhanesh1747/AlignX.git'
            }
        }

        stage('Check Build Tools') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'java -version && flutter --version'
                    } else {
                        bat 'java -version && flutter --version'
                    }
                }
            }
        }

        stage('Backend: Test and Package') {
            steps {
                dir('alignx_backend') {
                    script {
                        if (isUnix()) {
                            sh 'chmod +x mvnw && ./mvnw --batch-mode clean verify'
                        } else {
                            bat 'mvnw.cmd --batch-mode clean verify'
                        }
                    }
                }
            }
            post {
                always {
                    junit testResults: 'alignx_backend/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Frontend: Build Web') {
            steps {
                dir('alignx_frontend') {
                    script {
                        if (isUnix()) {
                            sh 'flutter pub get && flutter analyze && flutter build web --release'
                        } else {
                            bat 'flutter pub get && flutter analyze && flutter build web --release'
                        }
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'alignx_backend/target/*.jar, alignx_frontend/build/web/**', fingerprint: true
            }
        }
    }

    post {
        success {
            echo 'AlignX backend and Flutter web builds completed successfully.'
        }
        failure {
            echo 'AlignX CI failed. Review the stage logs above to find the failing command.'
        }
    }
}
