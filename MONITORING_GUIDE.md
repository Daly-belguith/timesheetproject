# 📊 Prometheus & Grafana - Guide d'Intégration

## 📋 Vue d'ensemble

Ce projet intègre **Prometheus** et **Grafana** pour monitorer complètement votre infrastructure DevOps, incluant:

- ✅ **Application Spring Boot** - via Spring Boot Actuator + Micrometer
- ✅ **Système Ubuntu** - via Node Exporter
- ✅ **Conteneurs Docker** - via cAdvisor
- ✅ **Jenkins CI/CD** - via Jenkins Prometheus Plugin
- ✅ **Dashboards Grafana** - Visualisation complète des métriques

---

## 🚀 Démarrage Rapide

### 1. Prérequis

- Docker & Docker Compose installés sur Ubuntu
- Maven & JDK 8+ (pour l'application Spring)
- Accès root ou sudo pour exécuter les commandes

### 2. Étapes de Déploiement

#### A. Sur votre machine Windows (Build)

```bash
# 1. Mettre à jour les dépendances Maven
mvn clean install

# 2. Compiler l'application
mvn clean compile

# 3. Créer le JAR
mvn clean package -DskipTests
```

#### B. Sur Ubuntu (Déploiement Docker)

```bash
# 1. Copier le projet sur Ubuntu
scp -r timesheetproject/ ubuntu@<IP>:/home/ubuntu/

# 2. Se connecter à Ubuntu
ssh ubuntu@<IP>

# 3. Accéder au répertoire du projet
cd /home/ubuntu/timesheetproject

# 4. Démarrer tous les services avec Docker Compose
docker-compose up -d

# 5. Vérifier le statut des conteneurs
docker-compose ps
```

---

## 🔧 Configuration

### Spring Boot Application

**Fichier modifié**: `src/main/resources/application.properties`

Les endpoints Actuator suivants sont maintenant disponibles:

```
# URL: http://localhost:8082/timesheet-devops/actuator/health
# URL: http://localhost:8082/timesheet-devops/actuator/metrics
# URL: http://localhost:8082/timesheet-devops/actuator/prometheus
```

#### Configurations activées:

```properties
# Prometheus & Micrometer
management.endpoints.web.exposure.include=health,metrics,prometheus
management.endpoint.health.show-details=always
management.metrics.export.prometheus.enabled=true
management.metrics.enable.jvm=true
management.metrics.enable.process=true
management.metrics.enable.logback=true
management.metrics.enable.tomcat=true
```

### Prometheus Configuration

**Fichier**: `prometheus.yml`

Les sources de scraping configurées:

| Service | Port | Endpoint | Intervalle |
|---------|------|----------|-----------|
| Prometheus Self | 9090 | `/metrics` | 15s |
| Spring App | 8082 | `/timesheet-devops/actuator/prometheus` | 15s |
| Node Exporter | 9100 | `/metrics` | 15s |
| cAdvisor | 8080 | `/metrics` | 15s |
| Jenkins | 8083 | `/prometheus` | 30s |

### Grafana Configuration

**Datasource**: Prometheus

Les dashboards provisionnés automatiquement:

1. **overview.json** - Vue d'ensemble des principales métriques
2. **spring-metrics.json** - Métriques de l'application Spring
3. **system-metrics.json** - Métriques du système Ubuntu
4. **docker-metrics.json** - Métriques des conteneurs Docker
5. **jenkins-metrics.json** - Métriques Jenkins CI/CD

---

## 📊 Accès aux Services

### Grafana
- **URL**: `http://<IP_Ubuntu>:3000`
- **Utilisateur**: `admin`
- **Mot de passe**: `admin`

### Prometheus
- **URL**: `http://<IP_Ubuntu>:9090`

### Node Exporter
- **URL**: `http://<IP_Ubuntu>:9100`

### cAdvisor
- **URL**: `http://<IP_Ubuntu>:8080`

### Application Spring
- **URL**: `http://<IP_Ubuntu>:8082/timesheet-devops`
- **Métriques**: `http://<IP_Ubuntu>:8082/timesheet-devops/actuator/prometheus`

---

## 📈 Dashboards Disponibles

### 1. Overview Dashboard
Affiche en temps réel:
- État de l'application Spring
- Utilisation CPU du système
- Utilisation disque
- Utilisation mémoire
- Tendances CPU et mémoire

### 2. Spring Boot Metrics
Monitore:
- Utilisation CPU de l'application
- Mémoire JVM (utilisée/max)
- Taux de requêtes HTTP
- Nombre de threads JVM
- Garbage Collection

### 3. System Metrics
Monitore:
- Utilisation CPU globale
- Utilisation mémoire système
- I/O réseau (RX/TX)
- Utilisation disque par partition

### 4. Docker Containers
Monitore:
- Utilisation CPU par conteneur
- Utilisation mémoire par conteneur
- I/O réseau par conteneur
- I/O disque par conteneur

### 5. Jenkins Metrics
Monitore:
- Nombre de builds par heure
- Durée des builds (p50, p99)
- Résultats des builds (succès/échecs)

---

## 🔍 Métriques Clés à Monitorer

### Spring Boot

```
# CPU
rate(process_cpu_seconds_total[5m]) * 100

# Mémoire JVM
jvm_memory_used_bytes
jvm_memory_max_bytes

# Requêtes HTTP
rate(http_server_requests_seconds_count[5m])
http_server_requests_seconds_max

# Threads
jvm_threads_live_threads
jvm_threads_peak_threads
```

### Système

```
# CPU
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Mémoire
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Disque
100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)

# Réseau
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Docker

```
# CPU des conteneurs
rate(container_cpu_cgroup_throttled_seconds_total[5m])

# Mémoire des conteneurs
container_memory_usage_bytes

# I/O Réseau
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])
```

---

## 🛠️ Commandes Utiles

### Docker Compose

```bash
# Démarrer tous les services
docker-compose up -d

# Arrêter tous les services
docker-compose down

# Voir les logs
docker-compose logs -f <service_name>

# Redémarrer un service
docker-compose restart <service_name>

# Voir l'état des services
docker-compose ps
```

### Vérification des Services

```bash
# Prometheus
curl http://localhost:9090/-/healthy

# Grafana
curl http://localhost:3000/api/health

# Node Exporter
curl http://localhost:9100/metrics | head -20

# Spring App
curl http://localhost:8082/timesheet-devops/actuator/prometheus | head -20
```

---

## 📝 Dépendances Ajoutées au pom.xml

```xml
<!-- Spring Boot Actuator -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<!-- Micrometer Registry Prometheus -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

---

## 📦 Structure des Fichiers

```
timesheetproject/
├── docker-compose.yml                 # Services Docker (Prometheus, Grafana, etc.)
├── prometheus.yml                     # Configuration Prometheus
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yml         # Configuration datasource
│       └── dashboards/
│           ├── overview.json          # Dashboard Overview
│           ├── spring-metrics.json    # Dashboard Spring Boot
│           ├── system-metrics.json    # Dashboard Ubuntu
│           ├── docker-metrics.json    # Dashboard Docker
│           └── jenkins-metrics.json   # Dashboard Jenkins
├── pom.xml                            # (MODIFIÉ) Dépendances Prometheus ajoutées
└── src/main/resources/
    └── application.properties         # (MODIFIÉ) Actuator configuré
```

---

## 🐛 Dépannage

### Prometheus ne scrape pas les métriques Spring

1. Vérifier que Spring est accessible:
   ```bash
   curl http://localhost:8082/timesheet-devops/actuator/prometheus
   ```

2. Modifier `prometheus.yml` si nécessaire
3. Redémarrer Prometheus:
   ```bash
   docker-compose restart prometheus
   ```

### Grafana n'affiche pas les données

1. Vérifier la datasource Prometheus:
   - Aller à: Configuration > Data Sources
   - Cliquer sur Prometheus
   - Tester la connexion

2. Vérifier les logs:
   ```bash
   docker-compose logs grafana
   docker-compose logs prometheus
   ```

### Jenkins n'est pas monitoré

1. Installer le plugin Prometheus sur Jenkins:
   - Jenkins > Manage Jenkins > Manage Plugins
   - Rechercher "Prometheus"
   - Installer et redémarrer Jenkins

2. L'endpoint sera disponible à: `http://localhost:8083/prometheus`

---

## 📚 Ressources

- [Prometheus Official Documentation](https://prometheus.io/docs/)
- [Grafana Official Documentation](https://grafana.com/docs/)
- [Spring Boot Actuator](https://spring.io/guides/gs/actuator-service/)
- [Micrometer](https://micrometer.io/)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [cAdvisor](https://github.com/google/cadvisor)

---

## 🎯 Prochaines Étapes

1. **Configurer des Alertes**:
   - Créer des règles d'alerte dans Prometheus
   - Intégrer Alertmanager

2. **Ajouter des Exporters Supplémentaires**:
   - MySQL Exporter pour la base de données
   - Nginx Exporter si vous utilisez Nginx

3. **Optimiser les Métriques**:
   - Ajuster les intervals de scrape
   - Créer des dashboards personnalisés

4. **Sauvegarder les Dashboards**:
   - Exporter les dashboards depuis Grafana
   - Stocker dans le repository git

---

**Créé le**: 18/04/2026  
**Dernière mise à jour**: 18/04/2026
