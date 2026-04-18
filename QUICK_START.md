# 🚀 Guide Rapide de Déploiement - Prometheus & Grafana

## 📋 Vue Rapide

Ce guide vous permettra de déployer complètement Prometheus et Grafana pour monitorer votre infrastructure en **moins de 10 minutes**.

---

## ⚡ Démarrage Rapide (3 étapes)

### Étape 1: Sur Windows - Construire le JAR

```powershell
# Ouvrir PowerShell dans le répertoire du projet
cd "c:\Users\moham\OneDrive\Desktop\devops tp\New folder\timesheetproject"

# Exécuter le script de déploiement
.\deploy-monitoring.ps1
```

Sélectionner l'option **2** pour construire l'application.

### Étape 2: Sur Ubuntu - Copier et Déployer

```powershell
# Dans le même script PowerShell, sélectionner l'option 4 (Construct + Deploy)
# Ou option 3 pour juste déployer si le JAR est déjà construit

# Entrez:
# - Adresse IP/hostname: <IP_Ubuntu>
# - Utilisateur SSH: ubuntu
# - Clé SSH: [optional]
```

### Étape 3: Accéder à Grafana

```
URL: http://<IP_Ubuntu>:3000
Utilisateur: admin
Mot de passe: admin
```

---

## 🔧 Mode Manuel (Pour Plus de Contrôle)

### Sur Windows:

```bash
# 1. Construire le projet
mvn clean install
mvn clean package -DskipTests

# 2. Copier vers Ubuntu (remplacer <IP> par l'adresse réelle)
scp -r . ubuntu@<IP>:/home/ubuntu/timesheet-monitoring

# Ou avec clé SSH:
scp -i c:\path\to\key.pem -r . ubuntu@<IP>:/home/ubuntu/timesheet-monitoring
```

### Sur Ubuntu:

```bash
# 1. Se connecter à Ubuntu
ssh ubuntu@<IP>

# 2. Naviguer vers le répertoire du projet
cd /home/ubuntu/timesheet-monitoring

# 3. Exécuter le script de déploiement
chmod +x deploy-monitoring.sh
sudo ./deploy-monitoring.sh

# 4. Vérifier le statut
docker-compose ps
```

---

## 📊 Vérification du Déploiement

### Via Navigateur Web:

| Service | URL |
|---------|-----|
| **Grafana** | http://<IP>:3000 |
| **Prometheus** | http://<IP>:9090 |
| **Node Exporter** | http://<IP>:9100 |
| **cAdvisor** | http://<IP>:8080 |
| **Spring App** | http://<IP>:8082/timesheet-devops |

### Via Terminal:

```bash
# Vérifier les conteneurs Docker
docker-compose ps

# Voir les logs
docker-compose logs -f prometheus

# Tester les endpoints
curl http://localhost:9090/-/healthy
curl http://localhost:3000/api/health
curl http://localhost:8082/timesheet-devops/actuator/prometheus
```

---

## 📈 Dashboards Disponibles

Une fois connecté à Grafana, vous trouverez les dashboards suivants:

1. **Overview** - Vue d'ensemble générale
2. **Spring Boot Metrics** - Application Spring
3. **System Metrics** - Ubuntu/Linux
4. **Docker Metrics** - Conteneurs
5. **Jenkins Metrics** - CI/CD

---

## 🛠️ Dépannage Rapide

### ❌ Les services Docker ne démarrent pas

```bash
# Vérifier les logs
docker-compose logs

# Redémarrer les services
docker-compose down
docker-compose up -d
```

### ❌ Grafana affiche "No Data"

1. Attendre 1-2 minutes (Prometheus doit d'abord scraper les données)
2. Vérifier Prometheus: http://<IP>:9090/targets
3. Redémarrer Prometheus: `docker-compose restart prometheus`

### ❌ Spring App n'est pas monitorée

1. Vérifier que l'app est accessible: `curl http://localhost:8082/timesheet-devops`
2. Vérifier les métriques: `curl http://localhost:8082/timesheet-devops/actuator/prometheus`
3. Vérifier prometheus.yml - le job Spring doit pointer vers le bon endpoint

### ❌ Jenkins n'est pas monitoré

1. Installer le plugin Prometheus sur Jenkins
2. Vérifier que Jenkins est sur le même réseau que Prometheus
3. Modifier prometheus.yml avec l'adresse correcte de Jenkins

---

## 📋 Checklist de Déploiement

- [ ] Maven et Java installés sur Windows
- [ ] Docker et Docker Compose installés sur Ubuntu
- [ ] Accès SSH à Ubuntu configuré
- [ ] Projet cloné ou copié sur Windows
- [ ] Script PowerShell exécuté avec succès
- [ ] Conteneurs Docker en cours d'exécution (`docker-compose ps`)
- [ ] Prometheus scrape les cibles (`http://<IP>:9090/targets`)
- [ ] Grafana accessible avec le mot de passe admin
- [ ] Dashboards visibles dans Grafana

---

## 📚 Documentation Complète

Pour la documentation détaillée, consulter: [MONITORING_GUIDE.md](MONITORING_GUIDE.md)

---

## 🎯 Étapes Suivantes

1. ✅ Personnaliser les dashboards Grafana
2. ✅ Configurer des alertes
3. ✅ Ajouter des exporters supplémentaires (MySQL, Nginx, etc.)
4. ✅ Intégrer Alertmanager pour les notifications
5. ✅ Mettre en place une sauvegarde Prometheus

---

## 📞 Support

Pour toute question ou problème:

1. Consulter la documentation officielle:
   - [Prometheus](https://prometheus.io/docs/)
   - [Grafana](https://grafana.com/docs/)

2. Vérifier les logs: `docker-compose logs <service>`

3. Redémarrer les services: `docker-compose restart`

---

**Bonne chance avec votre monitoring! 🎉**
