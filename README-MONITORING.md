# 📊 Timesheet DevOps - Monitoring avec Prometheus & Grafana

## ✨ Intégration Complète

Ce projet inclut maintenant une **solution de monitoring complète** basée sur:
- ✅ **Prometheus** - Collecte de métriques
- ✅ **Grafana** - Visualisation des données
- ✅ **Spring Boot Actuator** - Métriques de l'application
- ✅ **Node Exporter** - Métriques du système Ubuntu
- ✅ **cAdvisor** - Métriques des conteneurs Docker
- ✅ **Jenkins** - Métriques du CI/CD

---

## 🚀 Démarrage Rapide

### Option 1: Guide Rapide (Recommandé)

```bash
# Lire le guide de démarrage rapide
cat QUICK_START.md
```

### Option 2: Déploiement Complet

```powershell
# Sur Windows - Exécuter le script PowerShell
.\deploy-monitoring.ps1
```

---

## 📁 Structure du Projet

```
timesheetproject/
├── 📄 QUICK_START.md              # ⚡ Démarrage rapide (2 min de lecture)
├── 📄 MONITORING_GUIDE.md         # 📚 Documentation complète
├── 📄 README.md                   # 📖 Ce fichier
│
├── 🐳 DOCKER & MONITORING
├── docker-compose.yml              # Configuration Docker Compose
├── prometheus.yml                  # Configuration Prometheus
├── alert.yml                        # Règles d'alerte (optionnel)
│
├── 🔧 SCRIPTS DE DÉPLOIEMENT
├── deploy-monitoring.sh            # Script Linux/Bash
├── deploy-monitoring.ps1           # Script PowerShell (Windows)
│
├── 📊 GRAFANA
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yml      # Datasource Prometheus
│       └── dashboards/
│           ├── overview.json           # Dashboard Overview
│           ├── spring-metrics.json     # Dashboard Spring Boot
│           ├── system-metrics.json     # Dashboard Ubuntu
│           ├── docker-metrics.json     # Dashboard Docker
│           ├── jenkins-metrics.json    # Dashboard Jenkins
│           └── providers.yml           # Configuration dashboards
│
├── 🍃 APPLICATION SPRING
├── pom.xml                         # (MODIFIÉ) Dépendances ajoutées
├── src/main/resources/
│   └── application.properties      # (MODIFIÉ) Actuator configuré
│
└── ... (autres fichiers du projet)
```

---

## 🔄 Modifications Apportées

### 1. **pom.xml** - Dépendances Ajoutées

```xml
<!-- Spring Boot Actuator pour les métriques -->
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

### 2. **application.properties** - Configuration Actuator

```properties
# Exposition des endpoints Actuator
management.endpoints.web.exposure.include=health,metrics,prometheus
management.endpoint.health.show-details=always
management.metrics.export.prometheus.enabled=true
```

---

## 📊 Services Disponibles

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| **Grafana** | 3000 | http://localhost:3000 | Dashboards & Visualisation |
| **Prometheus** | 9090 | http://localhost:9090 | Base de données métriques |
| **Node Exporter** | 9100 | http://localhost:9100 | Métriques système |
| **cAdvisor** | 8080 | http://localhost:8080 | Métriques Docker |
| **Spring App** | 8082 | http://localhost:8082/timesheet-devops | Application métier |
| **Jenkins** | 8083 | http://localhost:8083 | CI/CD (externe) |

---

## 🎯 Dashboards Disponibles

### 1️⃣ **Overview Dashboard**
- État de santé global
- Utilisation CPU système
- Utilisation mémoire
- Utilisation disque
- Tendances temps réel

### 2️⃣ **Spring Boot Metrics**
- Utilisation CPU de l'application
- Mémoire JVM
- Taux de requêtes HTTP
- Nombre de threads
- Garbage Collection

### 3️⃣ **System Metrics** (Ubuntu)
- CPU par core
- Mémoire RAM
- I/O réseau
- Utilisation disque

### 4️⃣ **Docker Containers**
- CPU par conteneur
- Mémoire par conteneur
- I/O réseau
- I/O disque

### 5️⃣ **Jenkins CI/CD**
- Nombre de builds
- Durée des builds
- Taux de succès/échecs

---

## 🎓 Accès et Configuration

### Grafana
```
URL: http://<IP_Ubuntu>:3000
Utilisateur: admin
Mot de passe: admin
```

**Première connexion:**
1. Se connecter avec admin/admin
2. Changer le mot de passe (recommandé)
3. Les dashboards sont automatiquement importés
4. La datasource Prometheus est déjà configurée

### Prometheus
```
URL: http://<IP_Ubuntu>:9090
```

**Vérifier les cibles de scrape:**
- Aller à: Status > Targets
- Tous les jobs doivent être en vert

---

## 🔧 Configuration des Alertes (Optionnel)

Des règles d'alerte sont fournies dans `alert.yml`:

```bash
# Pour activer les alertes, décommenter dans prometheus.yml:
# rule_files:
#   - "alert.yml"

docker-compose restart prometheus
```

Les alertes incluent:
- ❌ Applications down
- ⚠️ Haute utilisation de ressources
- 🔴 Disque presque plein
- 📊 Anomalies de performance

---

## 🚀 Déploiement sur Ubuntu

### Étape 1: Préparer Windows
```powershell
mvn clean package -DskipTests
```

### Étape 2: Copier vers Ubuntu
```powershell
scp -r . ubuntu@<IP>:/home/ubuntu/timesheet-monitoring
ssh ubuntu@<IP>
```

### Étape 3: Déployer sur Ubuntu
```bash
cd /home/ubuntu/timesheet-monitoring
chmod +x deploy-monitoring.sh
sudo ./deploy-monitoring.sh
```

### Étape 4: Vérifier
```bash
docker-compose ps
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
```

---

## 📈 Requêtes Prometheus Utiles

### Spring Boot
```promql
# Utilisation CPU
rate(process_cpu_seconds_total[5m]) * 100

# Mémoire JVM
jvm_memory_used_bytes / jvm_memory_max_bytes * 100

# Taux d'erreurs HTTP
rate(http_server_requests_seconds_count{status=~"5.."}[5m])
```

### Système
```promql
# CPU système
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Mémoire disponible
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024

# Utilisation disque
100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)
```

### Docker
```promql
# Conteneurs actifs
count(container_last_seen)

# Mémoire totale utilisée
sum(container_memory_usage_bytes)
```

---

## 🛠️ Commandes Essentielles

### Docker Compose
```bash
# Démarrer
docker-compose up -d

# Arrêter
docker-compose down

# Logs
docker-compose logs -f <service>

# Redémarrer
docker-compose restart <service>

# Statut
docker-compose ps
```

### Vérification Rapide
```bash
# Prometheus
curl http://localhost:9090/api/v1/targets

# Grafana
curl http://localhost:3000/api/health

# Spring
curl http://localhost:8082/timesheet-devops/actuator/prometheus | head -20
```

---

## 📚 Documentation Détaillée

Pour la documentation complète et détaillée:
- **QUICK_START.md** - Guide de démarrage rapide
- **MONITORING_GUIDE.md** - Documentation technique complète

---

## 🐛 Dépannage

### Les dashboards Grafana sont vides?
```bash
# Attendre 1-2 minutes
# Prometheus doit d'abord scraper les données
# Vérifier: http://localhost:9090/targets
```

### Spring n'est pas monitorée?
```bash
# Vérifier l'endpoint
curl http://localhost:8082/timesheet-devops/actuator/prometheus

# Modifier prometheus.yml si nécessaire
docker-compose restart prometheus
```

### Docker Compose ne démarre pas?
```bash
# Vérifier les logs
docker-compose logs

# S'assurer que les ports ne sont pas utilisés
sudo lsof -i :9090
sudo lsof -i :3000
```

---

## 📋 Checklist de Déploiement

- [ ] Java et Maven installés sur Windows
- [ ] Docker et Docker Compose installés sur Ubuntu
- [ ] Application compilée: `mvn clean package -DskipTests`
- [ ] Fichiers copiés vers Ubuntu
- [ ] Script deploy-monitoring.sh exécuté
- [ ] Conteneurs Docker en cours d'exécution
- [ ] Prometheus scrape les cibles
- [ ] Grafana accessible à http://<IP>:3000
- [ ] Dashboards chargés dans Grafana

---

## 📞 Support & Ressources

### Documentation Officielle
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [Spring Boot Actuator](https://spring.io/guides/gs/actuator-service/)
- [Micrometer](https://micrometer.io/)

### Troubleshooting
1. Consulter MONITORING_GUIDE.md - Section Dépannage
2. Vérifier les logs: `docker-compose logs <service>`
3. Redémarrer les services: `docker-compose restart`

---

## 🎯 Prochaines Étapes

1. ✅ Personnaliser les dashboards Grafana
2. ✅ Configurer des alertes avancées
3. ✅ Ajouter des exporters supplémentaires (MySQL, etc.)
4. ✅ Intégrer Alertmanager
5. ✅ Mettre en place une sauvegarde Prometheus

---

## 📝 Notes Importantes

- **Credentials par défaut:**
  - Grafana: admin / admin ⚠️ Changer après première connexion!
  
- **Ports utilisés:**
  - 3000 (Grafana)
  - 9090 (Prometheus)
  - 9100 (Node Exporter)
  - 8080 (cAdvisor)

- **Volumes persistants:**
  - `prometheus_data` - Historique des métriques
  - `grafana_data` - Dashboards et configuration

---

## 📅 Dates

- **Créé:** 18/04/2026
- **Dernière mise à jour:** 18/04/2026
- **Version:** 1.0

---

## 🎉 C'est Prêt!

Votre infrastructure de monitoring est maintenant prête! 

**Rendez-vous sur Grafana pour commencer le monitoring:** http://localhost:3000

**Bonne surveillance! 📊**
