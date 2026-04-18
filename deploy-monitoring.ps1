#!/usr/bin/env powershell

<#
.SYNOPSIS
    Complete deployment script for Timesheet DevOps infrastructure and application
.DESCRIPTION
    Builds Spring app, deploys MySQL, Prometheus, Grafana, Node Exporter and starts everything
.PARAMETER DeployToRemote
    If $true, deploy to remote Ubuntu server
.PARAMETER SSHHost
    Remote server hostname/IP (required if DeployToRemote is true)
.PARAMETER SSHUser
    SSH username (default: vagrant)
.PARAMETER SSHKey
    Path to SSH private key file
#>

param(
    [Parameter(Mandatory=$false)]
    [bool]$DeployToRemote = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$SSHHost = "",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHUser = "vagrant",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHKey = ""
)

# Configuration
$SPRING_JAR = ".\target\timesheet-devops-1.0.jar"
$PROJECT_DIR = Get-Location

# Display functions
function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================`n" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Check requirements
function Check-Requirements {
    Write-Header "🔍 Vérification des Prérequis"

    # Maven
    try {
        $mavenVersion = mvn --version 2>&1 | Select-Object -First 1
        Write-Success "Maven: $mavenVersion"
    } catch {
        Write-Warning-Custom "Maven n'est pas installé"
    }

    # Java
    try {
        $javaVersion = java -version 2>&1 | Select-Object -First 1
        Write-Success "Java: $javaVersion"
    } catch {
        Write-Error-Custom "Java n'est pas installé"
        exit 1
    }

    # Git
    try {
        $gitVersion = git --version
        Write-Success "Git: $gitVersion"
    } catch {
        Write-Warning-Custom "Git n'est pas installé (optionnel)"
    }

    # If remote deployment
    if ($DeployToRemote) {
        # SSH
        try {
            ssh -V 2>&1 | Out-Null
            Write-Success "SSH: Disponible"
        } catch {
            Write-Error-Custom "SSH n'est pas disponible"
            exit 1
        }
    }
}

# Build Spring application
function Build-Application {
    Write-Header "🔨 Construction de l'Application Spring"

    if (-not (Test-Path "pom.xml")) {
        Write-Error-Custom "pom.xml non trouvé"
        exit 1
    }

    Write-Host "Exécution de: mvn clean compile..." -ForegroundColor Cyan
    mvn clean compile

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "La compilation a échoué"
        exit 1
    }

    Write-Host "Exécution de: mvn clean package -DskipTests..." -ForegroundColor Cyan
    mvn clean package -DskipTests

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "La création du package a échoué"
        exit 1
    }

    if (Test-Path $SPRING_JAR) {
        Write-Success "Application Spring construite: $SPRING_JAR"
    } else {
        Write-Error-Custom "Le JAR n'a pas été créé"
        exit 1
    }
}

# Deploy to remote Ubuntu via Vagrant SSH
function Deploy-ToVagrant {
    param(
        [string]$Host,
        [string]$User,
        [string]$KeyPath
    )

    Write-Header "🚀 Déploiement vers Vagrant ($Host)"

    if ([string]::IsNullOrEmpty($Host)) {
        Write-Error-Custom "Aucun hôte spécifié"
        exit 1
    }

    $remoteDir = "/home/$User/timesheet-monitoring"
    
    Write-Host "Copie du projet vers $Host..." -ForegroundColor Cyan
    
    $scpArgs = @("-r", ".", "$User@$Host`:$remoteDir/")
    if (-not [string]::IsNullOrEmpty($KeyPath)) {
        $scpArgs = @("-i", $KeyPath) + $scpArgs
    }
    
    & scp @scpArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "La copie SCP a échoué"
        exit 1
    }

    Write-Success "Projet copié vers $Host"

    Write-Host "Exécution du script de déploiement sur Ubuntu..." -ForegroundColor Cyan
    
    $sshArgs = @("$User@$Host")
    if (-not [string]::IsNullOrEmpty($KeyPath)) {
        $sshArgs = @("-i", $KeyPath) + $sshArgs
    }
    
    & ssh @sshArgs "cd $remoteDir && chmod +x deploy-monitoring.sh && ./deploy-monitoring.sh"

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Le déploiement sur Ubuntu a échoué"
        exit 1
    }

    Write-Success "Déploiement sur Ubuntu complété"
}

# Show access information
function Show-AccessInfo {
    param([string]$Host = "")

    Write-Header "✅ DÉPLOIEMENT RÉUSSI - Accès aux Services"

    if ([string]::IsNullOrEmpty($Host)) {
        $ip = "localhost"
        Write-Host "Services accessibles en LOCAL:" -ForegroundColor Green
    } else {
        $ip = $Host
        Write-Host "Services accessibles sur: $Host" -ForegroundColor Green
    }

    $info = @"

📊 GRAFANA (Dashboard de Monitoring)
   URL: http://$ip`:3000
   Utilisateur: admin
   Mot de passe: admin
   Dashboards: Overview, Spring Metrics, System Metrics, Jenkins Metrics

📈 PROMETHEUS (Base de données des métriques)
   URL: http://$ip`:9090
   Targets: http://$ip`:9090/targets

🖥️  NODE EXPORTER (Métriques système Ubuntu)
   URL: http://$ip`:9100/metrics

🗄️  MYSQL (Base de données)
   Host: localhost ou $ip
   Port: 3306
   Database: timesheet-devops-db
   User: timesheet
   Password: timesheet123

🍃 SPRING APPLICATION (Application Timesheet)
   URL: http://$ip`:8082/timesheet-devops
   Métriques Prometheus: http://$ip`:8082/timesheet-devops/actuator/prometheus
   Health: http://$ip`:8082/timesheet-devops/actuator/health
   API: http://$ip`:8082/timesheet-devops/api

🔍 JENKINS (CI/CD - si disponible)
   URL: http://$ip`:8080

📋 VOLUMES & DONNÉES:
   - Prometheus: prometheus_data (persist)
   - Grafana: grafana_data (persist)
   - MySQL: mysql_data (persist)

🛠️  COMMANDES DOCKER:
   - Voir les logs: docker-compose logs -f
   - Redémarrer les services: docker-compose restart
   - Arrêter les services: docker-compose down
   - Vérifier le status: docker-compose ps
   - Accès MySQL: docker exec -it mysql mysql -u timesheet -p

"@
    Write-Host $info
}

# Main deployment flow
function Main {
    Write-Host "
╔════════════════════════════════════════════════════════════╗
║  🚀 DÉPLOIEMENT COMPLET - INFRASTRUCTURE + APPLICATION 🚀  ║
║     Timesheet DevOps - Prometheus, Grafana, MySQL, Spring  ║
╚════════════════════════════════════════════════════════════╝
" -ForegroundColor Cyan

    Check-Requirements
    Build-Application

    if ($DeployToRemote) {
        if ([string]::IsNullOrEmpty($SSHHost)) {
            Write-Error-Custom "Vous devez spécifier SSHHost pour le déploiement distant"
            exit 1
        }
        
        Deploy-ToVagrant -Host $SSHHost -User $SSHUser -KeyPath $SSHKey
        Show-AccessInfo -Host $SSHHost
    } else {
        Write-Host "Pour déployer vers Vagrant, utilisez:" -ForegroundColor Yellow
        Write-Host "  .\deploy-monitoring.ps1 -DeployToRemote `$true -SSHHost <IP> -SSHUser vagrant" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Pour déploiement LOCAL:" -ForegroundColor Yellow
        Write-Host "  1. Copier le JAR vers le serveur Vagrant" -ForegroundColor Yellow
        Write-Host "  2. Dans Vagrant: docker-compose up -d" -ForegroundColor Yellow
        Write-Host "  3. Dans Vagrant: java -jar timesheet-devops-1.0.jar" -ForegroundColor Yellow
        Write-Host ""
        Show-AccessInfo
    }

    Write-Host "`n✅ Déploiement local préparé - Consultez les instructions ci-dessus`n" -ForegroundColor Green
}

# Run main
Main
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║     Timesheet DevOps - Déploiement     ║" -ForegroundColor Blue
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Blue
    
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-Host "1. Vérifier les prérequis"
    Write-Host "2. Construire l'application"
    Write-Host "3. Déployer vers Ubuntu"
    Write-Host "4. Construire + Déployer (complet)"
    Write-Host "5. Afficher les informations de connexion"
    Write-Host "6. Quitter"
    
    Write-Host "`nSélection: " -ForegroundColor Yellow -NoNewline
}

# Fonction principale
function Main {
    Clear-Host
    Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║   PROMETHEUS & GRAFANA - Script de Déploiement    ║" -ForegroundColor Blue
    Write-Host "║           Timesheet DevOps Project                 ║" -ForegroundColor Blue
    Write-Host "╚════════════════════════════════════════════════════╝`n" -ForegroundColor Blue

    # Si les paramètres sont fournis, exécuter directement
    if (-not [string]::IsNullOrEmpty($SSHHost) -or -not [string]::IsNullOrEmpty($SSHKey)) {
        Check-Requirements
        Build-Application
        
        if (-not [string]::IsNullOrEmpty($SSHHost)) {
            Deploy-ToUbuntu -Host $SSHHost -User $SSHUser -KeyPath $SSHKey
            Show-ConnectionInfo -Host $SSHHost
        } else {
            Show-ConnectionInfo
        }
    } else {
        # Mode interactif
        $continue = $true
        while ($continue) {
            Show-Menu
            $choice = Read-Host

            switch ($choice) {
                "1" {
                    Check-Requirements
                }
                "2" {
                    Build-Application
                }
                "3" {
                    $host = Read-Host "Adresse IP ou hostname Ubuntu"
                    $user = Read-Host "Utilisateur SSH (défaut: ubuntu)"
                    if ([string]::IsNullOrEmpty($user)) { $user = "ubuntu" }
                    
                    $useKey = Read-Host "Utiliser une clé SSH? (O/N)"
                    if ($useKey -eq "O" -or $useKey -eq "o") {
                        $keyPath = Read-Host "Chemin vers la clé SSH"
                        Deploy-ToUbuntu -Host $host -User $user -KeyPath $keyPath
                    } else {
                        Deploy-ToUbuntu -Host $host -User $user
                    }
                    
                    Show-ConnectionInfo -Host $host
                }
                "4" {
                    Check-Requirements
                    Build-Application
                    
                    $host = Read-Host "Adresse IP ou hostname Ubuntu"
                    $user = Read-Host "Utilisateur SSH (défaut: ubuntu)"
                    if ([string]::IsNullOrEmpty($user)) { $user = "ubuntu" }
                    
                    $useKey = Read-Host "Utiliser une clé SSH? (O/N)"
                    if ($useKey -eq "O" -or $useKey -eq "o") {
                        $keyPath = Read-Host "Chemin vers la clé SSH"
                        Deploy-ToUbuntu -Host $host -User $user -KeyPath $keyPath
                    } else {
                        Deploy-ToUbuntu -Host $host -User $user
                    }
                    
                    Show-ConnectionInfo -Host $host
                }
                "5" {
                    Show-ConnectionInfo
                }
                "6" {
                    $continue = $false
                    Write-Success "Au revoir!"
                }
                default {
                    Write-Warning-Custom "Option invalide"
                }
            }
        }
    }
}

# Exécuter
Main
