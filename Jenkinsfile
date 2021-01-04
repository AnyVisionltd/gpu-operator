pipeline {
    agent {
        label 'boto3'
    }
    options {
        timestamps()
        disableConcurrentBuilds()
        ansiColor('xterm')
        timeout(time: 3, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr:'100'))
    }
    libraries {
        lib('pipeline-library')
    }
    environment {
    	HELM_CATALOG_CRED = credentials('helm_catalog_services')
    	GRAVITY_PACKAGES_S3_BASE_URL = 's3://gravity-bundles/gpu-operator'
    }
    stages {
        stage('make') {
            steps {
                script {
                dir ("deployments/gpu-operator") {
                        sh("cp values.yaml.tmpl values.yaml")
                        env.HELM_DIR = "."
                        env.HELM_CHART_NAME="gpu-operator"
                        helmLib.helm_push()
                        sh("rm values.yaml")
//                         sh("ls -l && pwd && rm -f charts/gpu-operator/templates/resources-namespace.yaml")
                        // get chart info
                        def chart_name = sh(returnStdout: true, script: """cat Chart.yaml | grep ^name: | cut -d":" -f 2 |  tr -d "[:space:]" | tr -d '"' """).trim()
                        def chart_version = sh(returnStdout: true, script: """cat Chart.yaml | grep ^version: | cut -d":" -f 2 |  tr -d "[:space:]" | tr -d '"' """).trim()
                        def driver_version = sh(returnStdout: true, script: """yq r charts/gpu-operator/values.yaml driver.version | awk -F '.' {'print \$1"-"\$2'} """).trim()
                        // add helm services repo
                        helmLib.helm_init()
                        // build gravitiy package
                        gravityLib.make_package("Makefile", "build")
                        sh("ls -l && pwd")
                        // upload gravity package to s3
                        def s3_file_list = ["${chart_name}-${driver_version}-${chart_version}.tar","${chart_name}-${driver_version}-${chart_version}.md5"]
                        s3Lib.sync_files(".",s3_file_list,"${GRAVITY_PACKAGES_S3_BASE_URL}/${env.BRANCH_NAME}")
                    }
                }
                }
        }
    }
    post {
        success {
            cleanWs()
        }
    } // end of post
}
