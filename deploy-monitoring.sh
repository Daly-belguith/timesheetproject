#!/bin/bash

#############################################################
# Complete Infrastructure & Application Deployment Script
# Timesheet DevOps Project - Prometheus, Grafana, MySQL, Spring App
# Date: 2026-04-18
#############################################################

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SPRING_JAR_PATH="./target/timesheet-devops-1.0.jar"
SPRING_LOG_PATH="./logs/spring-app.log"
PROJECT_DIR="$(pwd)"

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
        print_warning "Maven n'est pas installé (vous devez avoir un JAR compilé)"
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

    if [ ! -d "logs" ]; then
        mkdir -p logs
        print_success "Répertoire logs créé"
    fi

    # Définir les permissions
    chmod 755 grafana -R
    print_success "Permissions configurées"
}

# Construire l'application Spring
build_spring_app() {
    print_header "Construction de l'Application Spring"

    if [ ! -f "pom.xml" ]; then
        print_error "pom.xml non trouvé"
        exit 1
    fi

    if ! command -v mvn &> /dev/null; then
        print_warning "Maven n'est pas disponible, en supposant que le JAR est compilé"
        return 0
    fi

    echo -e "${YELLOW}Exécution de: mvn clean package -DskipTests${NC}"
    mvn clean package -DskipTests

    if [ -f "$SPRING_JAR_PATH" ]; then
        print_success "Application Spring construite: $SPRING_JAR_PATH"
    else
        print_error "Le JAR n'a pas été créé"
        exit 1
    fi
}

# Arrêter les services existants
stop_existing_services() {
    print_header "Arrêt des Services Existants"

    if docker-compose ps | grep -q "Up"; then
        echo -e "${YELLOW}Arrêt des services Docker existants...${NC}"
        docker-compose down
        sleep 5
        print_success "Services arrêtés"
    else
        print_success "Aucun service Docker en cours d'exécution"
    fi
}

# Démarrer les services Docker (MySQL, Prometheus, Grafana, Node Exporter)
start_docker_services() {
    print_header "Démarrage des Services Docker"

    echo -e "${YELLOW}Démarrage de MySQL, Prometheus, Grafana, Node Exporter...${NC}"

    if docker-compose up -d; then
        print_success "Services Docker démarrés"
        sleep 15  # Attendre que MySQL soit prêt

        # Vérifier que les services sont en cours d'exécution
        if docker-compose ps | grep -q "Up"; then
            print_success "Services actifs et en cours d'exécution"
        else
            print_error "Certains services ne sont pas en cours d'exécution"
            docker-compose ps
            exit 1
        fi
    else
        print_error "Erreur lors du démarrage des services Docker"
        exit 1
    fi
}

# Initialiser la base de données MySQL
initialize_mysql() {
    print_header "Initialisation de la Base de Données MySQL"

    echo -e "${YELLOW}Attente que MySQL soit prêt...${NC}"
    sleep 10

    # Vérifier que MySQL est accessible
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker exec mysql mysql -u root -proot -e "SELECT 1;" > /dev/null 2>&1; then
            print_success "MySQL est prêt"
            break
        fi
        attempt=$((attempt + 1))
        echo -e "${YELLOW}Attente de MySQL... ($attempt/$max_attempts)${NC}"
        sleep 2
    done

    if [ $attempt -eq $max_attempts ]; then
        print_error "MySQL n'a pas répondu à temps"
        exit 1
    fi

    # Vérifier que la base de données existe
    if docker exec mysql mysql -u timesheet -ptimesheet123 -e "USE timesheet-devops-db;" 2>/dev/null; then
        print_success "Base de données MySQL existe et est accessible"
    else
        print_warning "Base de données sera créée par Hibernate au démarrage de l'application"
    fi
}

# Démarrer l'application Spring
start_spring_app() {
    print_header "Démarrage de l'Application Spring"

    if [ ! -f "$SPRING_JAR_PATH" ]; then
        print_error "Le JAR Spring n'a pas été trouvé: $SPRING_JAR_PATH"
        exit 1
    fi

    echo -e "${YELLOW}Lancement de l'application Spring en arrière-plan...${NC}"
    nohup java -jar "$SPRING_JAR_PATH" > "$SPRING_LOG_PATH" 2>&1 &
    SPRING_PID=$!
    print_success "Application Spring lancée (PID: $SPRING_PID)"

    # Attendre que l'application démarre
    echo -e "${YELLOW}Attente du démarrage de l'application Spring...${NC}"
    sleep 15

    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -sf http://localhost:8082/timesheet-devops/actuator/health > /dev/null 2>&1; then
            print_success "Application Spring est prête"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -e "${YELLOW}Attente de l'application Spring... ($attempt/$max_attempts)${NC}"
        sleep 2
    done

    print_error "L'application Spring n'a pas répondu à temps"
    echo -e "${RED}Consulter les logs: tail -f $SPRING_LOG_PATH${NC}"
    exit 1
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
        print_warning "Prometheus ne répond pas"
    fi

    # Vérifier Grafana
    echo -n "Vérification Grafana... "
    if curl -sf http://localhost:3000/api/health > /dev/null 2>&1; then
        print_success "Grafana est actif"
    else
        print_warning "Grafana ne répond pas"
    fi

    # Vérifier Node Exporter
    echo -n "Vérification Node Exporter... "
    if curl -sf http://localhost:9100/metrics > /dev/null 2>&1; then
        print_success "Node Exporter est actif"
    else
        print_warning "Node Exporter ne répond pas"
    fi

    # Vérifier Portainer
    echo -n "Vérification Portainer... "
    if curl -sf http://localhost:9000/api/status > /dev/null 2>&1; then
        print_success "Portainer est actif"
    else
        print_warning "Portainer ne répond pas"
    fi

    # Vérifier MySQL
    echo -n "Vérification MySQL... "
    if docker exec mysql mysql -u timesheet -ptimesheet123 -e "SELECT 1;" > /dev/null 2>&1; then
        print_success "MySQL est actif"
    else
        print_warning "MySQL ne répond pas"
    fi

    # Vérifier Spring App
    echo -n "Vérification Spring Application... "
    if curl -sf http://localhost:8082/timesheet-devops/actuator/health > /dev/null 2>&1; then
        print_success "Spring Application est active"
    else
        print_warning "Spring Application ne répond pas"
    fi

    echo ""
}

# Afficher les informations de connexion
show_access_info() {
    print_header "Informations d'Accès aux Services"

    LOCAL_IP=$(hostname -I | awk '{print $1}')

    cat << EOF
${GREEN}✓ DÉPLOIEMENT COMPLÉTÉ - Services accessibles:${NC}

📊 GRAFANA (Dashboard de Monitoring)
   URL: http://${LOCAL_IP}:3000
   Utilisateur: admin
   Mot de passe: admin
   Dashboards: Overview, Spring Metrics, System Metrics, Jenkins Metrics

📈 PROMETHEUS (Base de données des métriques)
   URL: http://${LOCAL_IP}:9090
   Targets: http://${LOCAL_IP}:9090/targets

🐳 PORTAINER (Docker Management UI + Container Metrics)
   URL: http://${LOCAL_IP}:9000
   Utilisateur: admin
   Mot de passe: admin123
   Features: Gérer conteneurs, images, volumes, logs, stats en temps réel

📊 DOCKER EXPORTER (Métriques Docker)
   Note: Utilisez Portainer pour voir les stats des conteneurs
   Alternative: docker stats (command line)

�🖥️  NODE EXPORTER (Métriques système Ubuntu)
   URL: http://${LOCAL_IP}:9100/metrics
   Données collectées: CPU, mémoire, disque, réseau

🗄️  MYSQL (Base de données)
   Host: localhost
   Port: 3306
   Database: timesheet-devops-db
   Utilisateur: timesheet
   Mot de passe: timesheet123
   Accès Docker: docker exec -it mysql mysql -u timesheet -p

🍃 SPRING APPLICATION (Application Timesheet)
   URL: http://${LOCAL_IP}:8082/timesheet-devops
   Métriques Prometheus: http://${LOCAL_IP}:8082/timesheet-devops/actuator/prometheus
   Health: http://${LOCAL_IP}:8082/timesheet-devops/actuator/health
   API: http://${LOCAL_IP}:8082/timesheet-devops/api

${YELLOW}🔍 Volumes et Données:${NC}
   - Prometheus: prometheus_data (persist)
   - Grafana: grafana_data (persist)
   - MySQL: mysql_data (persist)

${YELLOW}📋 Logs:${NC}
   - Spring App: $SPRING_LOG_PATH
   - Docker: docker-compose logs -f

${YELLOW}🛑 Commandes Utiles:${NC}
   - Voir les logs Spring: tail -f $SPRING_LOG_PATH
   - Voir tous les logs: docker-compose logs -f
   - Redémarrer les services: docker-compose restart
   - Arrêter les services: docker-compose down
   - Vérifier status: docker-compose ps

EOF
}

# Fonction principale
main() {
    print_header "🚀 DÉPLOIEMENT COMPLET - INFRASTRUCTURE + APPLICATION"

    check_requirements
    setup_directories
    stop_existing_services
    build_spring_app
    start_docker_services
    initialize_mysql
    start_spring_app
    verify_services
    show_access_info

    print_header "✅ DÉPLOIEMENT RÉUSSI!"
    echo -e "${GREEN}Rendez-vous sur Grafana pour commencer le monitoring.${NC}\n"
}

# Exécuter la fonction principale
main
