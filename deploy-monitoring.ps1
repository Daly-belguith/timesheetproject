#!/usr/bin/env powershell

<#
.SYNOPSIS
    Script de déploiement Prometheus & Grafana vers Ubuntu
.DESCRIPTION
    Ce script construit l'application Maven et la déploie sur Ubuntu avec Docker Compose
.PARAMETER SSHHost
    Adresse IP ou hostname du serveur Ubuntu
.PARAMETER SSHUser
    Utilisateur SSH (par défaut: ubuntu)
.PARAMETER SSHKey
    Chemin vers la clé SSH privée
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SSHHost = "",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHUser = "ubuntu",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHKey = ""
)

# Fonctions d'affichage
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

function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================`n" -ForegroundColor Blue
}

# Vérifier les prérequis
function Check-Requirements {
    Write-Header "Vérification des Prérequis"

    # Vérifier Maven
    try {
        $mavenVersion = mvn --version 2>&1 | Select-Object -First 1
        Write-Success "Maven: $mavenVersion"
    } catch {
        Write-Error-Custom "Maven n'est pas installé"
        Write-Host "Télécharger depuis: https://maven.apache.org/download.cgi"
        exit 1
    }

    # Vérifier Java
    try {
        $javaVersion = java -version 2>&1 | Select-Object -First 1
        Write-Success "Java: $javaVersion"
    } catch {
        Write-Error-Custom "Java n'est pas installé"
        exit 1
    }

    # Vérifier Git
    try {
        $gitVersion = git --version
        Write-Success "Git: $gitVersion"
    } catch {
        Write-Warning-Custom "Git n'est pas installé (optionnel)"
    }
}

# Construire l'application
function Build-Application {
    Write-Header "Construction de l'Application Maven"

    Write-Host "Exécution de: mvn clean compile..." -ForegroundColor Cyan
    mvn clean compile

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "La compilation a échoué"
        exit 1
    }

    Write-Success "Application compilée avec succès"

    Write-Host "Exécution de: mvn clean package -DskipTests..." -ForegroundColor Cyan
    mvn clean package -DskipTests

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "La création du package a échoué"
        exit 1
    }

    Write-Success "Package créé avec succès"
    Write-Host "JAR disponible dans: .\target\timesheet-devops-1.0.jar" -ForegroundColor Yellow
}

# Déployer vers Ubuntu
function Deploy-ToUbuntu {
    param(
        [string]$Host,
        [string]$User,
        [string]$KeyPath
    )

    Write-Header "Déploiement vers Ubuntu ($Host)"

    if ([string]::IsNullOrEmpty($Host)) {
        Write-Error-Custom "Aucun hôte spécifié"
        exit 1
    }

    $remoteDir = "/home/$User/timesheet-monitoring"
    
    # Construire la commande SCP
    $scpArgs = @()
    if (-not [string]::IsNullOrEmpty($KeyPath)) {
        $scpArgs += "-i", $KeyPath
    }
    $scpArgs += "-r", ".", "$User@$Host`:$remoteDir/"

    Write-Host "Copie du projet vers $Host..." -ForegroundColor Cyan
    scp @scpArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "La copie SSH a échoué"
        exit 1
    }

    Write-Success "Projet copié vers Ubuntu"

    # Construire la commande SSH pour exécuter le script de déploiement
    $sshArgs = @()
    if (-not [string]::IsNullOrEmpty($KeyPath)) {
        $sshArgs += "-i", $KeyPath
    }
    $sshArgs += "$User@$Host"

    Write-Host "Exécution du script de déploiement sur Ubuntu..." -ForegroundColor Cyan
    ssh @sshArgs "cd $remoteDir && chmod +x deploy-monitoring.sh && sudo ./deploy-monitoring.sh"

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Le déploiement sur Ubuntu a échoué"
        exit 1
    }

    Write-Success "Déploiement sur Ubuntu complété"
}

# Afficher les informations de connexion
function Show-ConnectionInfo {
    param(
        [string]$Host
    )

    Write-Header "Informations de Connexion"

    if ([string]::IsNullOrEmpty($Host)) {
        Write-Host "Services accessibles en local:" -ForegroundColor Green
    } else {
        Write-Host "Services accessibles sur: $Host" -ForegroundColor Green
    }

    $ip = if ([string]::IsNullOrEmpty($Host)) { "localhost" } else { $Host }

    @"

📊 GRAFANA
   URL: http://$ip:3000
   Utilisateur: admin
   Mot de passe: admin

📈 PROMETHEUS
   URL: http://$ip:9090

🖥️  NODE EXPORTER
   URL: http://$ip:9100/metrics

🐳 CADVISOR
   URL: http://$ip:8080

🍃 SPRING APPLICATION
   URL: http://$ip:8082/timesheet-devops
   Métriques: http://$ip:8082/timesheet-devops/actuator/prometheus

"@
}

# Menu interactif
function Show-Menu {
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
