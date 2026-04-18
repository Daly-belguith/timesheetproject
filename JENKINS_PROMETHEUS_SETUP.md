# 🔧 Configuration Jenkins pour Prometheus

## 📋 Vue d'Ensemble

Ce guide explique comment configurer Jenkins pour exposer des métriques Prometheus et les intégrer au monitoring.

---

## 1️⃣ Installation du Plugin Prometheus

### Étape 1: Accéder à Jenkins
```
URL: http://localhost:8083
```

### Étape 2: Installer le Plugin
1. Aller à: **Manage Jenkins** > **Manage Plugins**
2. Chercher: **"Prometheus metrics"**
3. Cocher: **Prometheus metrics**
4. Cliquer: **Install without restart**
5. Attendre la fin de l'installation

### Étape 3: Redémarrer Jenkins (Optionnel)
```bash
sudo service jenkins restart
# Ou via Docker
docker restart jenkins
```

---

## 2️⃣ Accès aux Métriques

Une fois le plugin installé, les métriques sont disponibles à:

```
http://localhost:8083/prometheus
```

### Vérifier que ça marche:
```bash
curl http://localhost:8083/prometheus | head -20
```

---

## 3️⃣ Configuration Prometheus

### Vérifier la configuration dans prometheus.yml

```yaml
- job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['localhost:8083']
        labels:
          service: 'jenkins'
          environment: 'ci-cd'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        replacement: 'jenkins'
    scrape_interval: 30s
    scrape_timeout: 10s
```

### Redémarrer Prometheus:
```bash
docker-compose restart prometheus
```

---

## 4️⃣ Métriques Jenkins Disponibles

### Builds
```promql
# Nombre total de builds
jenkins_builds_total

# Durée des builds
jenkins_build_duration_seconds

# Builds par résultat
jenkins_builds_total{result="success"}
jenkins_builds_total{result="failure"}
```

### Jobs
```promql
# Nombre total de jobs
jenkins_jobs_total

# Dernière exécution d'un job
jenkins_job_last_build_result_ordinal

# Dernier build par job
jenkins_job_last_build_timestamp_seconds
```

### Santé du Système
```promql
# Uptime de Jenkins
jenkins_uptime_seconds

# Exécuteurs libres/occupés
jenkins_executor_free
jenkins_executor_in_use
```

---

## 5️⃣ Exemple de Dashboard Jenkins

Les dashboards Grafana incluent déjà un dashboard Jenkins avec:

- ✅ Builds par heure
- ✅ Durée des builds
- ✅ Résultats (succès/échecs)
- ✅ Taux de réussite

**Accès:** Grafana > Dashboards > Jenkins Metrics

---

## 6️⃣ Requêtes PromQL Utiles

### Taux de Build
```promql
# Builds par minute
rate(jenkins_builds_total[1m])

# Builds réussis par heure
increase(jenkins_builds_total{result="success"}[1h])

# Taux d'échec
rate(jenkins_builds_total{result="failure"}[5m])
```

### Durée des Builds
```promql
# Durée moyenne
avg(jenkins_build_duration_seconds_sum / jenkins_build_duration_seconds_count)

# 99e percentile
histogram_quantile(0.99, rate(jenkins_build_duration_seconds_bucket[5m]))

# Builds lents (> 30 min)
jenkins_build_duration_seconds > 1800
```

### Jobs
```promql
# Jobs en échec
count(jenkins_job_last_build_result_ordinal{result="failure"})

# Succès des 10 derniers builds
topk(10, jenkins_job_last_build_result_ordinal)

# Jobs jamais exécutés
jenkins_job_last_build_timestamp_seconds == 0
```

---

## 7️⃣ Alertes Recommandées

Ajouter à `alert.yml`:

```yaml
- alert: JenkinsBuildFailureRate
  expr: rate(jenkins_builds_total{result="failure"}[1h]) > 0.3
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Taux d'échec Jenkins élevé"
    description: "Plus de 30% des builds échouent"

- alert: JenkinsBuildTimeHigh
  expr: histogram_quantile(0.95, rate(jenkins_build_duration_seconds_bucket[5m])) > 3600
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Builds Jenkins prennent trop de temps"
    description: "95e percentile dépasse 1h"

- alert: JenkinsDown
  expr: up{job="jenkins"} == 0
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "Jenkins est DOWN"
    description: "Jenkins n'est pas accessible"
```

---

## 8️⃣ Troubleshooting

### ❌ Endpoint /prometheus retourne 404

**Solution:**
1. Vérifier que le plugin est installé:
   - Manage Jenkins > Installed plugins
   - Chercher "Prometheus"

2. Redémarrer Jenkins:
   ```bash
   sudo systemctl restart jenkins
   ```

3. Vérifier la configuration:
   ```bash
   curl http://localhost:8083/prometheus
   ```

### ❌ Prometheus ne peut pas scraper Jenkins

**Solution:**
1. Vérifier la connectivité:
   ```bash
   curl http://localhost:8083/prometheus
   ```

2. Vérifier prometheus.yml:
   - L'adresse est-elle correcte?
   - Le port est-il accessible?
   - Le metrics_path est-il correct?

3. Redémarrer Prometheus:
   ```bash
   docker-compose restart prometheus
   ```

### ❌ Métriques vides dans Grafana

**Solution:**
1. Attendre 2-3 minutes (scraping interval = 30s)
2. Vérifier Prometheus Targets:
   - http://localhost:9090/targets
3. Vérifier que Jenkins a eu des builds

---

## 9️⃣ Configuration Avancée

### Scraper avec Authentification

Si Jenkins nécessite une authentification:

```yaml
- job_name: 'jenkins'
    metrics_path: '/prometheus'
    basic_auth:
      username: 'admin'
      password: 'password'
    static_configs:
      - targets: ['localhost:8083']
```

### Filtrer les Builds par Pipeline

```promql
# Builds d'un pipeline spécifique
jenkins_builds_total{job_name="mon-pipeline"}

# Builds d'une branche spécifique
jenkins_builds_total{branch="main"}
```

### Créer un Dashboard Personnalisé

Dans Grafana:
1. New Dashboard
2. Add Panel
3. Data source: Prometheus
4. Utiliser les requêtes PromQL ci-dessus

---

## 🔟 Ressources

- [Jenkins Prometheus Plugin](https://plugins.jenkins.io/prometheus/)
- [Prometheus Client Library](https://github.com/prometheus-community/prometheus-plugin-for-jenkins)
- [Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)

---

## 📋 Checklist

- [ ] Plugin Prometheus installé sur Jenkins
- [ ] Métriques accessibles: http://localhost:8083/prometheus
- [ ] prometheus.yml contient la configuration Jenkins
- [ ] Prometheus scrape avec succès Jenkins
- [ ] Dashboard Jenkins visible dans Grafana
- [ ] Données visibles dans les graphiques Jenkins

---

## 📝 Notes

- **Metrics Path:** `/prometheus` (pas `/metrics`)
- **Scrape Interval:** 30s (peut être changé dans prometheus.yml)
- **Retention:** Les métriques sont retenues selon la politique Prometheus
- **Performance:** L'endpoint /prometheus peut être gourmand sur Jenkins busy

---

**Configuration Jenkins complétée! ✅**

Rendez-vous sur Grafana pour voir les métriques Jenkins: http://localhost:3000 > Jenkins Metrics

---

**Dernière mise à jour:** 18/04/2026
