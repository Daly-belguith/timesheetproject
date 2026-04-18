# 🐳 Portainer & Docker Exporter Guide

## What Changed

Replaced **cAdvisor** (which had Docker Compose compatibility issues) with:

1. **Portainer** - Full Docker management UI with metrics
2. **Docker Exporter** - Prometheus-native Docker metrics collection

---

## 🌐 Portainer - Docker Management UI

### Access Portainer

```
URL: http://<SERVER_IP>:9000
Initial Username: admin
Initial Password: admin123
```

### First Login Setup

1. Navigate to http://<IP>:9000
2. Set admin password (will be prompted)
3. Click "Connect" to connect to Local Docker
4. Browse containers, images, volumes, networks

### Key Features

- **Dashboard**: Overview of all containers, images, volumes
- **Containers**: Start, stop, restart, remove containers
- **Logs**: View container logs in real-time
- **Stats**: CPU, memory, network usage per container
- **Volumes**: Manage persistent storage
- **Networks**: View and manage Docker networks

---

## 📊 Docker Exporter - Prometheus Metrics

### What It Does

- Exports Docker container metrics (CPU, memory, network, I/O)
- Integrates directly with Prometheus on port **9323**
- Automatically discovered by Prometheus scraper

### Available Metrics

```
# Container metrics
docker_container_cpu_usage_percent
docker_container_memory_usage_percent
docker_container_network_io_bytes

# Build info
docker_build_info

# Example PromQL queries:
up{job="docker-exporter"}                           # Is exporter up?
docker_container_memory_usage_bytes                 # Container memory
rate(docker_container_network_io_bytes[5m])        # Network throughput
```

### Verify it's Working

```bash
# Check Docker Exporter metrics endpoint
curl http://localhost:9323/metrics | grep docker_container

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.job="docker-exporter")'
```

---

## 📈 Grafana Dashboard for Docker Metrics

### Existing Dashboard

- **docker-metrics.json** - Pre-configured dashboard showing:
  - Container CPU usage
  - Container memory usage
  - Network I/O
  - Container status
  - Disk I/O

### Verify Data Appears

1. Open Grafana: http://<IP>:3000
2. Go to **Dashboards** → **Docker Metrics**
3. Wait 1-2 minutes for data collection
4. Should see graphs populate with container metrics

---

## 🚀 Docker Compose Services

New/Updated Services:

```yaml
portainer:
  - Port: 9000 (UI)
  - Port: 8000 (Agent)
  - Volume: portainer_data
  - Healthcheck: Enabled

docker-exporter:
  - Port: 9323 (Metrics)
  - Volume: /var/run/docker.sock (Docker access)
  - Healthcheck: Enabled
```

### Deployment

```bash
# Start all services
docker-compose up -d

# Verify services
docker-compose ps

# Check specific services
docker-compose ps portainer
docker-compose ps docker-exporter

# View logs
docker-compose logs -f portainer
docker-compose logs -f docker-exporter
```

---

## 🔍 Prometheus Configuration

Both services automatically scraped:

```yaml
# In prometheus.yml
- job_name: 'docker-exporter'
  targets: ['docker-exporter:9323']
  scrape_interval: 15s

- job_name: 'portainer'
  targets: ['portainer:9000']
  scrape_interval: 30s
```

### Verify Scraping

```bash
# Check targets in Prometheus UI
http://localhost:9090/targets

# Look for:
- docker-exporter: UP ✅
- portainer: UP ✅
```

---

## 📊 Complete Monitoring Stack

| Component | Port | Purpose | Status |
|-----------|------|---------|--------|
| **Portainer** | 9000 | Docker UI + management | ✅ Active |
| **Docker Exporter** | 9323 | Docker metrics to Prometheus | ✅ Active |
| **Prometheus** | 9090 | Metrics database | ✅ Active |
| **Grafana** | 3000 | Dashboards | ✅ Active |
| **Spring App** | 8082 | Application metrics | ✅ Active |
| **Node Exporter** | 9100 | System metrics | ✅ Active |
| **MySQL** | 3306 | Database | ✅ Active |

---

## 🛠️ Useful Commands

### Portainer Management

```bash
# View Portainer logs
docker-compose logs -f portainer

# Restart Portainer
docker-compose restart portainer

# Access Portainer database
docker exec portainer ls -la /data

# Reset Portainer password (admin)
# See Portainer documentation for details
```

### Docker Exporter Troubleshooting

```bash
# Check exporter metrics
curl http://localhost:9323/metrics | head -20

# Check exporter logs
docker-compose logs -f docker-exporter

# Verify Docker socket access
docker exec docker-exporter ls -la /var/run/docker.sock
```

### Container Management via Portainer CLI

```bash
# Or use Docker commands directly
docker ps -a                    # List all containers
docker stats                    # Real-time stats
docker logs <container_id>      # View logs
docker inspect <container_id>   # Detailed info
```

---

## 🔐 Security Notes

### Default Credentials

- **Portainer**: admin / admin123 (set your own on first login)
- **Docker Exporter**: No authentication (runs in Docker network)

### Recommendations

1. Change Portainer password on first login
2. Disable Portainer public IP if not needed
3. Restrict Docker socket access to Portainer container
4. Consider edge cases: don't expose port 9000 externally without TLS

### Enable TLS for Portainer

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout portainer.key -out portainer.crt

# Update docker-compose.yml to use TLS
# And access via https://localhost:9000
```

---

## 📚 Additional Resources

- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Exporter Metrics](https://github.com/prometheuscommunity/docker_exporter)
- [Prometheus Docker Integration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Grafana Docker Dashboard](https://grafana.com/grafana/dashboards/docker)

---

## ✅ Deployment Checklist

- [ ] docker-compose.yml has portainer and docker-exporter services
- [ ] prometheus.yml has docker-exporter and portainer jobs
- [ ] All services running: `docker-compose ps`
- [ ] Portainer accessible: http://<IP>:9000
- [ ] Docker Exporter metrics: http://localhost:9323/metrics
- [ ] Prometheus targets UP: http://localhost:9090/targets
- [ ] Grafana Docker dashboard shows data after 1-2 minutes

---

## 🎉 Benefits of This Setup

✅ **Better than cAdvisor:**
- ✅ No compatibility issues with Docker Compose 1.29.2
- ✅ Portainer provides full Docker UI (cAdvisor was metrics-only)
- ✅ Docker Exporter is lightweight and Prometheus-native
- ✅ Portainer can manage containers directly
- ✅ Both integrate seamlessly with Grafana

**Last Updated:** 2026-04-18

See also:
- [DATABASE_SETUP.md](DATABASE_SETUP.md)
- [COMPLETE_DEPLOYMENT_GUIDE.md](COMPLETE_DEPLOYMENT_GUIDE.md)
- [MONITORING_GUIDE.md](MONITORING_GUIDE.md)
