pipeline {
    agent none

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Lint') {
            agent {
                dockerfile {
                    filename 'Dockerfile.ci'
                    label 'docker && amd64'
                }
            }
            steps {
                sh 'luacheck lua/ --config .luacheckrc'
            }
            post { cleanup { cleanWs() } }
        }

        stage('Startup') {
            parallel {

                stage('Linux amd64') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ci'
                            label 'docker && amd64'
                        }
                    }
                    steps { script { nvimStartupLinux() } }
                    post { cleanup { cleanWs() } }
                }

                stage('Linux arm64') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ci'
                            label 'docker && arm64'
                        }
                    }
                    steps { script { nvimStartupLinux() } }
                    post { cleanup { cleanWs() } }
                }

                stage('Windows') {
                    agent { label 'windows' }
                    steps { script { nvimStartupWindows() } }
                    post { cleanup { cleanWs() } }
                }
            }
        }
    }

    post {
        failure {
            echo 'CI failed – please check the logs.'
        }
    }
}

def nvimStartupLinux() {
    sh '''
        TMP=$(mktemp -d)
        export XDG_CONFIG_HOME="$TMP/config"
        export XDG_DATA_HOME="$TMP/data"
        export XDG_STATE_HOME="$TMP/state"
        export XDG_CACHE_HOME="$TMP/cache"

        mkdir -p "$XDG_CONFIG_HOME/nvim"
        cp -r . "$XDG_CONFIG_HOME/nvim/"

        echo "==> nvim headless startup ($(uname -m) linux)"
        nvim --headless "+Lazy! sync" "+qa" 2>&1

        rm -rf "$TMP"
    '''
}

def nvimStartupWindows() {
    powershell '''
        $ErrorActionPreference = "Stop"

        # Isolated config/data directory to keep the agent workspace clean
        $tmp = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
        $env:XDG_CONFIG_HOME = "$tmp\\config"
        $env:XDG_DATA_HOME   = "$tmp\\data"
        $env:XDG_STATE_HOME  = "$tmp\\state"
        $env:XDG_CACHE_HOME  = "$tmp\\cache"

        New-Item -ItemType Directory -Path "$env:XDG_CONFIG_HOME\\nvim" -Force | Out-Null
        Copy-Item -Recurse -Path . -Destination "$env:XDG_CONFIG_HOME\\nvim"

        Write-Host "==> nvim headless startup (windows)"
        & nvim --headless "+Lazy! sync" "+qa"
        if ($LASTEXITCODE -ne 0) {
            throw "nvim exited with code $LASTEXITCODE"
        }

        Remove-Item -Recurse -Force $tmp
    '''
}
