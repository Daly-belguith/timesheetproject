pipeline {
    agent any

    tools {
        jdk 'JAVA_HOME'
        maven 'M2_HOME'
    }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '5'))
    }

    environment {
        SONARQUBE_URL = 'http://localhost:9000'
        SONARQUBE_TOKEN = credentials('sonarqube-token')
        PROJECT_KEY = 'timesheetproject'
        MAVEN_OPTS = '-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '========== Checking out code =========='
                git branch: 'master',
                    url: 'https://github.com/Daly-belguith/timesheetproject.git'
                echo '✓ Code checked out successfully'
            }
        }

        stage('Build') {
            steps {
                echo '========== Building project =========='
                sh 'mvn clean compile'
                echo '✓ Build completed successfully'
            }
        }

        stage('Test') {
            steps {
                echo '========== Running unit tests =========='
                sh 'mvn test'
                echo '✓ Tests completed'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '========== Running SonarQube Analysis =========='
                sh '''
                    mvn clean verify sonar:sonar \
                      -Dsonar.projectKey=${PROJECT_KEY} \
                      -Dsonar.host.url=${SONARQUBE_URL} \
                      -Dsonar.login=${SONARQUBE_TOKEN} \
                      -Dsonar.sources=src/main/java \
                      -Dsonar.tests=src/test/java \
                      -Dsonar.java.binaries=target/classes
                '''
                echo '✓ SonarQube analysis completed'
            }
        }

        stage('Package') {
            steps {
                echo '========== Packaging application =========='
                sh 'mvn package -DskipTests'
                echo '✓ Application packaged successfully'
            }
        }
    }

    post {
        always {
            echo '========== Publishing Test Reports =========='
            junit '**/target/surefire-reports/*.xml'
            
            // Archive artifacts
            archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
            
            // Clean workspace
            cleanWs()
        }

        success {
            echo '✓✓✓ Pipeline completed successfully! ✓✓✓'
            echo "Artifact location: ${BUILD_URL}artifact/target/"
        }

        failure {
            echo '✗✗✗ Pipeline failed! Check logs above for details. ✗✗✗'
        }

        unstable {
            echo '⚠ Pipeline completed with warnings'
        }
    }
}
