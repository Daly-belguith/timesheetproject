# 🚀 Complete Deployment Guide - Timesheet DevOps

This guide covers deploying the **entire infrastructure** including MySQL, Prometheus, Grafana, Spring App, and monitoring.

---

## 📋 What Gets Deployed

| Component | Port | Purpose | Status |
|-----------|------|---------|--------|
| **Spring Application** | 8082 | Main application | ✅ Deployed |
| **MySQL Database** | 3306 | Data persistence | ✅ Docker |
| **Prometheus** | 9090 | Metrics collection | ✅ Docker |
| **Grafana** | 3000 | Visualization dashboards | ✅ Docker |
| **Node Exporter** | 9100 | System metrics | ✅ Docker |
| **Jenkins** | 8080 | CI/CD pipeline | ⚠️ Optional |

---

## 🔧 Prerequisites

### On Your Local Machine (Windows)

- ✅ Java 8+ (`java -version`)
- ✅ Maven 3.6+ (`mvn --version`)
- ✅ Git (optional)
- ✅ PowerShell or terminal

### On Vagrant/Ubuntu Server

- ✅ Docker & Docker Compose
- ✅ Java 8+ (optional, for running app outside Docker)
- ✅ curl (for health checks)

---

## 📥 Option 1: Deploy to Local Vagrant VM

### Step 1: Build the Application (Windows)

```powershell
# In PowerShell on your Windows machine
cd "c:\Users\moham\OneDrive\Desktop\devops tp\New folder\timesheetproject"

# Build JAR
mvn clean package -DskipTests

# Verify JAR was created
ls target\timesheet-devops-1.0.jar
```

### Step 2: Copy Everything to Vagrant

```powershell
# Copy entire project to Vagrant home
vagrant scp . :/home/vagrant/timesheet-monitoring

# Or use SSH directly
scp -r . vagrant@<IP>:/home/vagrant/timesheet-monitoring
```

### Step 3: Run Deployment Script on Vagrant

```bash
# SSH into Vagrant
vagrant ssh

# Navigate to project
cd ~/timesheet-monitoring

# Make script executable
chmod +x deploy-monitoring.sh

# Run complete deployment
./deploy-monitoring.sh
```

This will:
1. ✅ Check requirements (Docker, Java, MySQL)
2. ✅ Create necessary directories
3. ✅ Start MySQL in Docker
4. ✅ Initialize MySQL database
5. ✅ Start Prometheus, Grafana, Node Exporter (Docker)
6. ✅ Build Spring app (if Maven available)
7. ✅ Start Spring application
8. ✅ Verify all services
9. ✅ Display access information

---

## 📥 Option 2: Deploy from Windows (Remote Deployment)

### Using PowerShell Script

```powershell
# Windows PowerShell
cd "c:\Users\moham\OneDrive\Desktop\devops tp\New folder\timesheetproject"

# Deploy to Vagrant
.\deploy-monitoring.ps1 -DeployToRemote $true -SSHHost <VAGRANT_IP> -SSHUser vagrant

# Example:
.\deploy-monitoring.ps1 -DeployToRemote $true -SSHHost 192.168.1.100 -SSHUser vagrant
```

This script will:
1. ✅ Build Spring application locally
2. ✅ Copy entire project to Vagrant via SCP
3. ✅ SSH into Vagrant and run the deployment script

---

## 🎯 Quick Deployment (3 Commands)

```bash
# 1. On Vagrant/Ubuntu - Start all Docker containers
docker-compose up -d

# 2. Wait for MySQL to be ready
sleep 15

# 3. Run Spring application
java -jar target/timesheet-devops-1.0.jar
```

---

## 🌐 Access Your Services

After deployment, services are available at:

### Grafana (Monitoring Dashboards)
```
URL: http://<SERVER_IP>:3000
Username: admin
Password: admin

Available Dashboards:
- Overview: System and application summary
- Spring Boot Metrics: JVM, HTTP requests, threads
- System Metrics: CPU, memory, disk, network
- Jenkins Metrics: Build rates, success/failure
```

### Prometheus (Metrics Database)
```
URL: http://<SERVER_IP>:9090/targets
Scrape Jobs:
- prometheus: Self-monitoring
- timesheet-devops: Spring app metrics
- ubuntu-node: System metrics
- jenkins: CI/CD metrics (if installed)
```

### Spring Application
```
API: http://<SERVER_IP>:8082/timesheet-devops
Health: http://<SERVER_IP>:8082/timesheet-devops/actuator/health
Metrics: http://<SERVER_IP>:8082/timesheet-devops/actuator/prometheus
```

### MySQL Database
```
Host: localhost or <SERVER_IP>
Port: 3306
Database: timesheet-devops-db
Username: timesheet
Password: timesheet123

Docker access:
docker exec -it mysql mysql -u timesheet -p timesheet-devops-db
```

---

## 🛠️ Useful Commands

### Docker Management

```bash
# View all running services
docker-compose ps

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker-compose logs -f mysql
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Remove all data (careful!)
docker-compose down -v
```

### MySQL Management

```bash
# Connect to MySQL
docker exec -it mysql mysql -u timesheet -p timesheet-devops-db
# Password: timesheet123

# Backup database
docker exec mysql mysqldump -u timesheet -p timesheet-devops-db > backup.sql

# Restore database
docker exec -i mysql mysql -u timesheet -p timesheet-devops-db < backup.sql

# View database size
docker exec mysql mysql -u root -proot -e \
  "SELECT table_name, (data_length+index_length) as size_bytes FROM information_schema.tables WHERE table_schema='timesheet-devops-db';"
```

### Spring Application

```bash
# View Spring logs
tail -f logs/spring-app.log

# Restart Spring app
pkill -f "java -jar"
java -jar target/timesheet-devops-1.0.jar &

# Check Spring health
curl http://localhost:8082/timesheet-devops/actuator/health | jq

# View metrics
curl http://localhost:8082/timesheet-devops/actuator/metrics | jq
```

### Prometheus

```bash
# Query Prometheus API
curl 'http://localhost:9090/api/v1/query?query=up'

# Check scrape targets
curl http://localhost:9090/api/v1/targets | jq

# Check for scrape errors
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health=="down")'
```

---

## 🔍 Troubleshooting

### MySQL Not Starting

```bash
# Check MySQL logs
docker-compose logs mysql

# Verify MySQL health
docker-compose ps mysql

# Force restart
docker-compose down
docker volume rm timesheetproject_mysql_data  # WARNING: Deletes data!
docker-compose up -d mysql
sleep 20
```

### Spring App Not Connecting to MySQL

```bash
# Check Spring logs
tail -f logs/spring-app.log | grep -i mysql

# Verify MySQL is running and accessible
docker exec mysql mysql -u timesheet -ptimesheet123 -e "SELECT 1;"

# Test connection from host
mysql -h localhost -u timesheet -ptimesheet123 -e "USE \`timesheet-devops-db\`; SELECT 1;"
```

### Prometheus Not Scraping Metrics

```bash
# Check Prometheus logs
docker-compose logs prometheus

# Verify targets
curl http://localhost:9090/api/v1/targets

# Check specific target health
curl 'http://localhost:9090/api/v1/targets?filter=job:"timesheet-devops"'

# Restart Prometheus
docker-compose restart prometheus
sleep 10
```

### Grafana Dashboards Showing No Data

1. Wait 1-2 minutes for Prometheus to collect metrics
2. Verify Prometheus targets are "UP": http://localhost:9090/targets
3. Check Spring app is running: `curl http://localhost:8082/timesheet-devops/actuator/health`
4. Force Grafana refresh (Ctrl+Shift+R)
5. Check Grafana data source is configured correctly in Settings

---

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Windows Machine                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  .\deploy-monitoring.ps1                             │  │
│  │  - Builds Spring JAR                                 │  │
│  │  - Transfers to Vagrant via SCP                      │  │
│  │  - Executes deploy script on Ubuntu                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │ SSH/SCP
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   Vagrant/Ubuntu VM                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ./deploy-monitoring.sh                              │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │ Docker Services (docker-compose)             │    │  │
│  │  │                                               │    │  │
│  │  │  ┌──────────┐ ┌──────────┐ ┌────────────┐  │    │  │
│  │  │  │  MySQL   │ │Prometheus│ │  Grafana   │  │    │  │
│  │  │  │  :3306   │ │  :9090   │ │  :3000     │  │    │  │
│  │  │  └──────────┘ └──────────┘ └────────────┘  │    │  │
│  │  │                                               │    │  │
│  │  │  ┌─────────────────┐                         │    │  │
│  │  │  │ Node Exporter   │                         │    │  │
│  │  │  │ :9100           │                         │    │  │
│  │  │  └─────────────────┘                         │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  │                                                       │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │  Spring Application (Host)                  │    │  │
│  │  │  java -jar timesheet-devops-1.0.jar         │    │  │
│  │  │  :8082                                       │    │  │
│  │  │  ├─ /timesheet-devops (REST API)            │    │  │
│  │  │  ├─ /actuator/health (Health check)         │    │  │
│  │  │  └─ /actuator/prometheus (Metrics export)   │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Persistent Volumes:                                       │
│  - mysql_data (MySQL database files)                       │
│  - prometheus_data (Prometheus time-series DB)             │
│  - grafana_data (Grafana dashboards & settings)            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Deployment Checklist

- [ ] Java 8+ installed on local machine
- [ ] Maven 3.6+ installed on local machine
- [ ] Access to Vagrant VM via SSH
- [ ] Docker installed on Vagrant/Ubuntu
- [ ] Docker Compose installed on Vagrant/Ubuntu
- [ ] Project copied to Vagrant
- [ ] `deploy-monitoring.sh` is executable (`chmod +x`)
- [ ] MySQL starts successfully (`docker-compose ps`)
- [ ] Spring app starts successfully (check logs)
- [ ] Can access Grafana at http://<IP>:3000
- [ ] Prometheus targets are UP at http://<IP>:9090/targets
- [ ] Spring metrics appear in Grafana dashboards

---

## 🔐 Security Notes

⚠️ **Default Credentials (CHANGE FOR PRODUCTION):**

- Grafana: admin/admin
- MySQL: timesheet/timesheet123
- MySQL Root: root/root

### Change Grafana Password

1. Login to Grafana: http://<IP>:3000
2. Click user icon → Change Password
3. Enter new password

### Change MySQL Password

```bash
# Connect to MySQL
docker exec -it mysql mysql -u root -proot

# Inside MySQL:
ALTER USER 'timesheet'@'%' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
EXIT;
```

Then update `application.properties`:
```properties
spring.datasource.password=new_password
```

---

## 📚 Documentation References

- [Spring Boot Actuator](https://spring.io/guides/gs/actuating-web-application/)
- [Micrometer Prometheus](https://micrometer.io/docs/registry/prometheus)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [MySQL Docker Image](https://hub.docker.com/_/mysql)
- [Docker Compose](https://docs.docker.com/compose/)

---

## 🆘 Getting Help

### Check Deployment Logs

```bash
# Last deployment
cat deploy-monitoring.log

# Docker logs
docker-compose logs

# Spring app logs
tail -f logs/spring-app.log

# System logs
journalctl -xe
```

### Test Connectivity

```bash
# Test each service endpoint
curl http://localhost:9090/-/healthy        # Prometheus
curl http://localhost:3000/api/health       # Grafana
curl http://localhost:9100/metrics          # Node Exporter
curl http://localhost:8082/timesheet-devops/actuator/health  # Spring

# If any fail, check that service's logs
docker-compose logs <service_name>
```

---

**Last Updated:** 2026-04-18

For more information, see:
- [DATABASE_SETUP.md](DATABASE_SETUP.md)
- [QUICK_START.md](QUICK_START.md)
- [MONITORING_GUIDE.md](MONITORING_GUIDE.md)
