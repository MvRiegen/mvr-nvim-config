pipeline {
    agent none

    options {
        quietPeriod(120)
        disableConcurrentBuilds()
        timeout(time: 60, unit: 'MINUTES')
	    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '30')
        ansiColor('gnome-terminal')
    }

    stages {
        stage('Build CI Images') {
            parallel {
                stage('amd64') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ci'
                            label 'docker && amd64'
                        }
                    }
                    steps {
                        sh 'luarocks --version'
                    }
                    post { always { cleanWs() } }
                }
                stage('arm64') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ci'
                            label 'docker && arm64'
                        }
                    }
                    steps {
                        sh 'luarocks --version'
                    }
                    post { always { cleanWs() } }
                }
            }
        }

        stage('Lint') {
            agent {
                dockerfile {
                    filename 'Dockerfile.ci'
                    label 'docker && (amd64 || arm64)'
                }
            }
            steps {
                script {
                    def status = sh(returnStatus: true, script: '''
                        set +e
                        luacheck lua/ tests/ --config .luacheckrc --formatter plain --codes --no-color > luacheck.log 2>&1
                        LUACHECK_STATUS=$?
                        set -e

                        cat luacheck.log
                        nvim --headless -u NONE -l tests/checkstyle_from_log.lua luacheck.log luacheck-checkstyle.xml luacheck
                        exit $LUACHECK_STATUS
                    ''')
                    recordIssues(
                        enabledForFailure: true,
                        tools: [checkStyle(id: 'luacheck', name: 'Luacheck', pattern: 'luacheck-checkstyle.xml')]
                    )
                    if (status != 0) {
                        error("luacheck failed with exit code ${status}")
                    }
                }
            }
            post { always { cleanWs() } }
        }

        stage('LuaLS') {
            agent {
                dockerfile {
                    filename 'Dockerfile.ci'
                    label 'docker && (amd64 || arm64)'
                }
            }
            steps {
                script {
                    def status = sh(returnStatus: true, script: '''
                        set +e
                        lua-language-server --check . --checklevel=Warning --configpath=.luarc.json > luals.log 2>&1
                        LUALS_STATUS=$?
                        set -e

                        cat luals.log
                        nvim --headless -u NONE -l tests/checkstyle_from_log.lua luals.log luals-checkstyle.xml luals
                        exit $LUALS_STATUS
                    ''')
                    recordIssues(
                        enabledForFailure: true,
                        tools: [checkStyle(id: 'luals', name: 'LuaLS', pattern: 'luals-checkstyle.xml')]
                    )
                    if (status != 0) {
                        error("LuaLS failed with exit code ${status}")
                    }
                }
            }
            post { always { cleanWs() } }
        }

        stage('Unit') {
            agent {
                dockerfile {
                    filename 'Dockerfile.ci'
                    label 'docker && (amd64 || arm64)'
                }
            }
            steps {
                sh '''
                    set -e
                    TMP=$(mktemp -d)
                    trap 'rm -rf "$TMP"' EXIT

                    export HOME="$TMP/home"
                    export XDG_CONFIG_HOME="$TMP/config"
                    export XDG_DATA_HOME="$TMP/data"
                    export XDG_STATE_HOME="$TMP/state"
                    export XDG_CACHE_HOME="$TMP/cache"
                    mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

                    export PLENARY_PATH="$TMP/plenary.nvim"

                    git clone --filter=blob:none https://github.com/nvim-lua/plenary.nvim "$PLENARY_PATH"
                    git -C "$PLENARY_PATH" checkout --quiet 74b06c6c75e4eeb3108ec01852001636d85a932b

                    set +e
                    nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/unit { minimal_init = 'tests/minimal_init.lua' }" > unit.log 2>&1
                    UNIT_STATUS=$?
                    set -e

                    cat unit.log
                    nvim --headless -u NONE -l tests/plenary_to_junit.lua unit.log unit-results.xml
                    exit $UNIT_STATUS
                '''
            }
            post {
                always {
                    junit allowEmptyResults: false, testResults: 'unit-results.xml'
                    cleanWs()
                }
            }
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
                    post { always { cleanWs() } }
                }

                stage('Linux arm64') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ci'
                            label 'docker && arm64'
                        }
                    }
                    steps { script { nvimStartupLinux() } }
                    post { always { cleanWs() } }
                }

                stage('Windows') {
                    agent { label 'windows' }
                    steps { script { nvimStartupWindows() } }
                    post { always { cleanWs() } }
                }
            }
        }
    }

    post {
        failure { echo 'CI failed – please check the logs.' }
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
        timeout 300 nvim --headless -c "Lazy sync" -c "qa" 2>&1
        EXIT=$?
        rm -rf "$TMP"
        [ $EXIT -eq 0 ] || exit $EXIT
    '''
}

def nvimStartupWindows() {
    powershell '''
        $ErrorActionPreference = 'Stop'

        function Remove-PathWithRetry {
            param(
                [Parameter(Mandatory = $true)]
                [string] $Path,
                [int] $Attempts = 6,
                [int] $DelaySeconds = 2
            )

            if (-not (Test-Path -LiteralPath $Path)) {
                return
            }

            for ($i = 1; $i -le $Attempts; $i++) {
                try {
                    Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
                    return
                } catch {
                    if ($i -eq $Attempts) {
                        throw
                    }

                    Write-Warning ("Cleanup failed for {0} (attempt {1}/{2}): {3}" -f $Path, $i, $Attempts, $_.Exception.Message)
                    Start-Sleep -Seconds $DelaySeconds
                }
            }
        }

        # Isolated config/data directory to keep the agent workspace clean
        $tmp = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
        $env:XDG_CONFIG_HOME = $tmp + '\\config'
        $env:XDG_DATA_HOME   = $tmp + '\\data'
        $env:XDG_STATE_HOME  = $tmp + '\\state'
        $env:XDG_CACHE_HOME  = $tmp + '\\cache'

        $nvimCfg = $env:XDG_CONFIG_HOME + '\\nvim'
        New-Item -ItemType Directory -Path $nvimCfg -Force | Out-Null
        Get-ChildItem -Force | Copy-Item -Recurse -Destination $nvimCfg -Force

        Write-Host '==> nvim headless startup (windows)'
        $nvimExitCode = 0
        try {
            & nvim --headless -c 'Lazy sync' -c 'qa'
            $nvimExitCode = $LASTEXITCODE
        } finally {
            Remove-PathWithRetry -Path $tmp
        }

        if ($nvimExitCode -ne 0) {
            throw ('nvim exited with code ' + $nvimExitCode)
        }
    '''
}
