# 🗄️ Database Configuration Guide

## 📋 Current Setup

Your application is now configured with **MySQL 5.7 in Docker**.

---

## ✅ MySQL in Docker (Recommended - Current Setup)

### Configuration

**File**: `application.properties`

```properties
# Docker configuration (default)
spring.datasource.url=jdbc:mysql://mysql:3306/timesheet-devops-db
spring.datasource.username=timesheet
spring.datasource.password=timesheet123
```

**MySQL Details**:
- Host: `mysql` (Docker internal DNS)
- Port: `3306`
- Database: `timesheet-devops-db`
- User: `timesheet`
- Password: `timesheet123`
- Root Password: `root`

### Deployment

```bash
# MySQL starts automatically with docker-compose
docker-compose up -d

# Verify MySQL is running
docker-compose ps

# Check MySQL logs
docker-compose logs mysql
```

### Access MySQL from CLI

```bash
# From Vagrant SSH terminal
docker exec -it mysql mysql -u timesheet -p
# Password: timesheet123

# Or as root
docker exec -it mysql mysql -u root -p
# Password: root
```

### Verify Database

```bash
# Connect to MySQL
docker exec -it mysql mysql -u timesheet -p timesheet-devops-db

# Inside MySQL shell
SHOW TABLES;
DESC Employe;  -- Check if tables exist
EXIT;
```

---

## 🚀 Deploy Your Application

### Option 1: Run Spring App on Vagrant Host

```bash
# Build JAR on Windows
cd "c:\Users\moham\OneDrive\Desktop\devops tp\New folder\timesheetproject"
mvn clean package -DskipTests

# Copy to Vagrant
vagrant scp target/timesheet-devops-1.0.jar :/home/vagrant/

# Run on Vagrant
vagrant ssh
cd ~
java -jar timesheet-devops-1.0.jar
```

### Option 2: Containerize Spring App (Advanced)

Add to `docker-compose.yml`:

```yaml
spring-app:
  build: .
  container_name: spring-app
  ports:
    - "8082:8082"
  environment:
    SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/timesheet-devops-db
    SPRING_DATASOURCE_USERNAME: timesheet
    SPRING_DATASOURCE_PASSWORD: timesheet123
  depends_on:
    - mysql
  networks:
    - monitoring
```

---

## 💾 Alternative: In-Memory H2 Database

If you prefer a **lightweight in-memory database** without MySQL:

### Step 1: Add H2 Dependency to pom.xml

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

### Step 2: Update application.properties

```properties
# H2 In-Memory Database (for testing/demo)
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# Enable H2 console (optional)
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console

# JPA/Hibernate
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
```

### Access H2 Console

```
http://localhost:8082/timesheet-devops/h2-console
JDBC URL: jdbc:h2:mem:testdb
User: sa
Password: (leave blank)
```

---

## 📊 Database Persistence

### MySQL (Docker Volume)

Data is **persistent** in the Docker volume `mysql_data`:

```bash
# Data survives docker-compose down
docker-compose down
docker volume ls  # mysql_data is still there

# Data is lost when volume is deleted
docker volume rm mysql_data
```

### H2 (In-Memory)

Data is **lost** when the application stops:
- ✅ Good for testing
- ❌ Not for production

---

## 🔧 Switching Between Databases

### To Use MySQL (Current)
```properties
spring.datasource.url=jdbc:mysql://mysql:3306/timesheet-devops-db
spring.datasource.username=timesheet
spring.datasource.password=timesheet123
spring.jpa.hibernate.ddl-auto=update
```

### To Use H2
```properties
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
```

Just update `application.properties` and restart the app!

---

## 🛠️ Useful Commands

### MySQL Management

```bash
# Connect to MySQL
docker exec -it mysql mysql -u timesheet -p timesheet-devops-db

# Backup database
docker exec mysql mysqldump -u timesheet -p timesheet-devops-db > backup.sql

# Restore database
docker exec -i mysql mysql -u timesheet -p timesheet-devops-db < backup.sql

# View MySQL logs
docker-compose logs -f mysql

# Restart MySQL
docker-compose restart mysql
```

### Check Data

```bash
# Inside MySQL
SHOW DATABASES;
USE timesheet-devops-db;
SHOW TABLES;
SELECT COUNT(*) FROM Employe;
```

---

## ⚠️ Important Notes

1. **First Run**: Hibernate will create tables automatically (`ddl-auto=update`)
2. **Credentials**: Change default MySQL credentials for production
3. **Networking**: Spring app must use `mysql` hostname (not `localhost`) when in Docker
4. **Persistence**: MySQL data is stored in Docker volume `mysql_data`

---

## 📋 Checklist

- [ ] MySQL container running: `docker-compose ps`
- [ ] MySQL accessible: `docker exec -it mysql mysql -u root -p`
- [ ] Database created: `mysql-devops-db` exists
- [ ] Spring app configured to use `mysql:3306`
- [ ] Spring app running: `java -jar timesheet-devops-1.0.jar`
- [ ] Tables created automatically by Hibernate
- [ ] Prometheus scraping Spring metrics: `http://localhost:9090/targets`
- [ ] Grafana showing data: `http://localhost:3000`

---

## 📚 Documentation

- [MySQL Docker Image](https://hub.docker.com/_/mysql)
- [Spring Boot Database Configuration](https://spring.io/guides/gs/accessing-data-mysql/)
- [H2 Database](https://www.h2database.com/)
- [Hibernate DDL Auto](https://hibernate.org/orm/documentation/)

---

**MySQL is ready! Deploy your Spring app now.** 🚀
