#!/bin/bash

#############################################################
# Script d'Installation et Déploiement - Prometheus & Grafana
# Timesheet DevOps Project
# Date: 2026-04-18
#############################################################

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Vérification des prérequis
check_requirements() {
    print_header "Vérification des Prérequis"

    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé"
        echo "Installation: sudo apt-get install docker.io"
        exit 1
    fi
    print_success "Docker est installé: $(docker --version)"

    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose n'est pas installé"
        echo "Installation: sudo apt-get install docker-compose"
        exit 1
    fi
    print_success "Docker Compose est installé: $(docker-compose --version)"

    # Vérifier Java
    if ! command -v java &> /dev/null; then
        print_error "Java n'est pas installé"
        echo "Installation: sudo apt-get install openjdk-8-jdk"
        exit 1
    fi
    print_success "Java est installé: $(java -version 2>&1 | head -n 1)"

    # Vérifier Maven
    if ! command -v mvn &> /dev/null; then
        print_warning "Maven n'est pas installé (optionnel si le JAR est déjà construit)"
    else
        print_success "Maven est installé: $(mvn --version | head -n 1)"
    fi
}

# Créer les répertoires nécessaires
setup_directories() {
    print_header "Configuration des Répertoires"

    if [ ! -d "grafana/provisioning/datasources" ]; then
        mkdir -p grafana/provisioning/datasources
        print_success "Répertoire Grafana datasources créé"
    fi

    if [ ! -d "grafana/provisioning/dashboards" ]; then
        mkdir -p grafana/provisioning/dashboards
        print_success "Répertoire Grafana dashboards créé"
    fi

    # Définir les permissions
    chmod 755 grafana -R
    print_success "Permissions configurées"
}

# Démarrer les services Docker
start_services() {
    print_header "Démarrage des Services Docker"

    echo -e "${YELLOW}Démarrage de Prometheus, Grafana, Node Exporter, et cAdvisor...${NC}"

    if docker-compose up -d; then
        print_success "Services Docker démarrés"
        sleep 10

        # Vérifier que les services sont en cours d'exécution
        if docker-compose ps | grep -q "Up"; then
            print_success "Services actifs et en cours d'exécution"
        else
            print_error "Certains services ne sont pas en cours d'exécution"
            docker-compose ps
        fi
    else
        print_error "Erreur lors du démarrage des services Docker"
        exit 1
    fi
}

# Vérifier la connectivité des services
verify_services() {
    print_header "Vérification de la Connectivité des Services"

    # Obtenir l'adresse IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    echo -e "${YELLOW}Adresse IP locale: ${LOCAL_IP}${NC}\n"

    # Vérifier Prometheus
    echo -n "Vérification Prometheus... "
    if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then
        print_success "Prometheus est actif"
    else
        print_warning "Prometheus ne répond pas (il peut prendre du temps)"
    fi

    # Vérifier Grafana
    echo -n "Vérification Grafana... "
    if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
        print_success "Grafana est actif"
    else
        print_warning "Grafana ne répond pas (il peut prendre du temps)"
    fi

    # Vérifier Node Exporter
    echo -n "Vérification Node Exporter... "
    if curl -sf http://localhost:9100/metrics > /dev/null 2>&1; then
        print_success "Node Exporter est actif"
    else
        print_warning "Node Exporter ne répond pas"
    fi

    # Vérifier cAdvisor
    echo -n "Vérification cAdvisor... "
    if curl -sf http://localhost:8080/api/v1/spec > /dev/null 2>&1; then
        print_success "cAdvisor est actif"
    else
        print_warning "cAdvisor ne répond pas (il peut prendre du temps)"
    fi

    echo ""
}

# Afficher les informations de connexion
show_access_info() {
    print_header "Informations d'Accès aux Services"

    LOCAL_IP=$(hostname -I | awk '{print $1}')

    cat << EOF
${GREEN}Services maintenant accessibles:${NC}

📊 GRAFANA
   URL: http://${LOCAL_IP}:3000
   Utilisateur: admin
   Mot de passe: admin
   Dashboards: Overview, Spring Metrics, System Metrics, Docker Metrics, Jenkins Metrics

📈 PROMETHEUS
   URL: http://${LOCAL_IP}:9090
   Targets: http://${LOCAL_IP}:9090/targets

🖥️  NODE EXPORTER (Système Ubuntu)
   URL: http://${LOCAL_IP}:9100/metrics

🐳 CADVISOR (Docker Containers)
   URL: http://${LOCAL_IP}:8080

🍃 SPRING APPLICATION
   URL: http://${LOCAL_IP}:8082/timesheet-devops
   Métriques Prometheus: http://${LOCAL_IP}:8082/timesheet-devops/actuator/prometheus
   Health: http://${LOCAL_IP}:8082/timesheet-devops/actuator/health

${YELLOW}Configuration Docker Compose:${NC}
   - Prometheus: port 9090
   - Grafana: port 3000
   - Node Exporter: port 9100
   - cAdvisor: port 8080

${YELLOW}Volume de données:${NC}
   - Prometheus: prometheus_data
   - Grafana: grafana_data

EOF
}

# Afficher les commandes utiles
show_useful_commands() {
    print_header "Commandes Utiles"

    cat << EOF
${GREEN}Gestion des services:${NC}

# Arrêter tous les services
docker-compose down

# Voir les logs en temps réel
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Redémarrer un service
docker-compose restart prometheus

# Voir l'état des services
docker-compose ps

${GREEN}Métriques et diagnostic:${NC}

# Vérifier les cibles Prometheus
curl http://localhost:9090/api/v1/targets

# Tester Spring Actuator
curl http://localhost:8082/timesheet-devops/actuator/health

# Afficher les 10 premières métriques Prometheus
curl http://localhost:9090/api/v1/series?match[]=up | head -10

${GREEN}Documentation:${NC}

# Voir le guide complet
cat MONITORING_GUIDE.md

EOF
}

# Fonction principale
main() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   PROMETHEUS & GRAFANA - Installation & Déploiement ║"
    echo "║           Timesheet DevOps Project                  ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"

    # Vérifier que nous sommes dans le bon répertoire
    if [ ! -f "docker-compose.yml" ]; then
        print_error "Erreur: docker-compose.yml non trouvé"
        echo "Assurez-vous d'exécuter ce script depuis le répertoire racine du projet"
        exit 1
    fi

    # Exécuter les étapes
    check_requirements
    setup_directories
    start_services
    sleep 5
    verify_services
    show_access_info
    show_useful_commands

    print_header "Installation Terminée ✓"
    echo -e "${GREEN}Tous les services sont maintenant en cours d'exécution!${NC}"
    echo -e "${GREEN}Rendez-vous sur Grafana pour commencer le monitoring.${NC}\n"
}

# Exécuter la fonction principale
main
