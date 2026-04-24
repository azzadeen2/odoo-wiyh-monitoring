# Odoo 17 Docker Deployment with Monitoring

Production-ready Docker deployment for Odoo 17 with load balancing, connection pooling, Redis session management, and full observability stack (Prometheus, Grafana, Loki, Alloy).

## Architecture

```
                            Client Browser
                                  |
                         +--------v--------+
                         |  Nginx (8077)   |
                         |  Load Balancer  |
                         +--------+--------+
                    +-------------+-------------+
                    |             |             |
              +-----v-----+ +----v------+ +----v------+
              |  Odoo #1  | |  Odoo #2  | |  Odoo #3  |
              |  (8069)   | |  (8069)   | |  (8069)   |
              +-----+-----+ +----+------+ +----+------+
                    |             |             |
                    +-------------+-------------+
                                  |             
                           +------v------+ 
                           | PgBouncer   | 
                           |  (6432)     | 
                           +------+------+ 
                                  |
                           +------v------+
                           | PostgreSQL  |
                           |  15 (5432)  |
                           +-------------+

              +-------------------------------+
              |       Monitoring Stack        |
              |  Prometheus (9091)            |
              |  Grafana (3001)               |
              |  Loki (3100) + Alloy          |
              |  Exporters: PG, PgB, Nginx    |
              +-------------------------------+
```

## Services

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| **nginx** | nginx:alpine | 8077 | Load balancer and reverse proxy |
| **odoo17-ssys** | odoo17-ssys:latest | 8069 (internal) | Odoo 17 (3 replicas) |
| **pgbouncer** | edoburu/pgbouncer | 6432 (internal) | PostgreSQL connection pooler |
| **db15** | postgres:15 | 5432 (internal) | PostgreSQL database |
| **pgadmin** | dpage/pgadmin4 | 5051 | Database management UI |
| **prometheus** | prom/prometheus | 9091 | Metrics collection and storage |
| **grafana** | grafana/grafana | 3001 | Dashboards and visualization |
| **loki** | grafana/loki:3.7.0 | 3100 | Log aggregation |
| **alloy** | grafana/alloy | - | Log collection agent |
| **postgres-exporter** | prometheuscommunity/postgres-exporter | 9187 (internal) | PostgreSQL metrics |
| **pgbouncer-exporter** | prometheuscommunity/pgbouncer-exporter | 9127 (internal) | PgBouncer metrics |
| **nginx-exporter** | nginx/nginx-prometheus-exporter | 9113 (internal) | Nginx metrics |

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
nano .env
```

### 2. Setup Permissions

```bash
chmod +x run.sh
./run.sh
chmod +x build-odoo-image.sh
./build-odoo-image.sh
```

### 3. Start Services

```bash
docker compose up -d
```

### 4. Access

| Service | URL | Credentials |
|---------|-----|-------------|
| Odoo | http://localhost:8077 | Set on first visit |
| PgAdmin | http://localhost:5051 | See `.env` |
| Grafana | http://localhost:3001 | See `.env` |
| Prometheus | http://localhost:9091 | - |

## Configuration

### Environment Variables (`.env`)

```env
# Database
POSTGRES_USER=odoo
POSTGRES_PASSWORD=your_password
POSTGRES_DB=postgres

# Odoo Database (for PgBouncer)
ODOO_DB_NAME=odoo17db
ODOO_USER=odoo
ODOO_PASSWORD=your_password

# PgAdmin
PGADMIN_EMAIL=admin@admin.com
PGADMIN_PASSWORD=admin



# Monitoring
GRAFANA_PORT=3001
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin@2026
PROMETHEUS_PORT=9091
LOKI_PORT=3100
```

### Odoo Configuration (`config/odoo.conf`)

The database connection is configured in `config/odoo.conf`. For best performance, connect through PgBouncer:

```ini
db_host = pgbouncer
db_port = 6432
```

For initial installation, connect directly to PostgreSQL to avoid PgBouncer-related issues:

```ini
db_host = db15
db_port = 5432
```

## Monitoring

### Grafana Dashboards

Grafana is auto-provisioned with:
- **Prometheus** datasource for metrics
- **Loki** datasource for logs
- **Odoo Infrastructure Overview** dashboard with panels for PostgreSQL, PgBouncer, Nginx, and Redis

### What is Monitored

| Component | Metrics |
|-----------|---------|
| PostgreSQL | Connections, TPS, database size, locks, replication |
| PgBouncer | Pool connections (active/idle/waiting), query duration |
| Nginx | Requests/sec, active connections, dropped connections |
| Docker | All container logs collected via Alloy |
| Host | Syslog, auth logs, kernel logs |

### Log Querying (Loki)

In Grafana Explore, use LogQL:

```logql
{job="docker"}                                    # All container logs
{job="docker", container="loki"}                   # Specific container
{job="docker", container=~"odoo17-ssys.*"}         # All Odoo replicas
{job="docker"} |= "error"                          # Logs containing "error"
{job="syslog"}                                      # Host syslog
```

### Odoo Application Metrics

To enable Odoo metrics in Prometheus, install the `prometheus_exporter` addon from the Odoo Apps Store (available for versions 13-18, by Mint System GmbH). Once installed, Prometheus will automatically scrape Odoo's `/metrics` endpoint.


## Directory Structure

```
deploy-odoo-main/
├── docker-compose.yml              # Main orchestration file
├── docker-compose-redis.yml        # Full stack with Redis + custom build
├── .env                            # Environment variables
├── .env.example                    # Environment template
├── run.sh                          # Permissions setup script
├── build-odoo-image.sh             # Custom Odoo image builder
├── config/
│   ├── odoo.conf                   # Odoo configuration (active)
│   └── odoo.conf.example           # Odoo configuration template
├── nginx/
│   └── nginx.conf                  # Nginx load balancer config
├── odoo/
│   ├── Dockerfile                  # Custom Odoo image
│   ├── docker-entrypoint.sh        # Custom entrypoint
│   └── requirement.txt             # Python packages
├── pgbouncer/
│   └── userlist.txt                # PgBouncer authentication
├── monitoring/
│   ├── prometheus.yml              # Prometheus scrape config
│   ├── loki-config.yaml            # Loki storage config
│   ├── alloy-config.alloy          # Alloy log collection config
│   └── grafana/
│       └── provisioning/
│           ├── datasources/
│           │   └── datasources.yml  # Auto-provisioned datasources
│           └── dashboards/
│               ├── dashboard.yml    # Dashboard provider
│               └── odoo-overview.json  # Pre-built dashboard
└── addons2/                         # Additional modules directory
```

## Scaling

Adjust Odoo replicas:

```bash
docker compose up -d --scale odoo17-ssys=5
```

Or edit `docker-compose.yml`:

```yaml
odoo17-ssys:
  deploy:
    replicas: 5
```

## Data Persistence

| Volume | Purpose |
|--------|---------|
| `odoo-web-session` | Odoo sessions |
| `odoo-web-filestore` | Odoo filestore and attachments |
| `odoo-db-data` | PostgreSQL data |
| `nginx-logs` | Nginx access and error logs |
| `prometheus-data` | Prometheus metrics (30-day retention) |
| `grafana-data` | Grafana dashboards and settings |
| `loki-data` | Log storage (7-day retention) |

### Backup

```bash
# Database backup
docker exec odoo-sales_db15_1 pg_dump -U odoo odoo17db > backup.sql

# Filestore backup
docker cp odoo-sales_odoo17-ssys_1:/var/lib/odoo ./odoo-filestore-backup
```

## Troubleshooting

```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f odoo17-ssys
docker compose logs -f prometheus
docker compose logs -f loki

# Check service status
docker compose ps

# Check Prometheus targets
curl http://localhost:9091/api/v1/targets

# Check Loki readiness
curl http://localhost:3100/ready

# Nginx health
curl http://localhost:8077/nginx-health
```

### Common Issues

| Issue | Solution |
|-------|----------|
| 502 Bad Gateway | Wait for Odoo startup, check `docker compose logs odoo17-ssys` |
| Database connection error | Verify PgBouncer health and credentials |
| Upload fails | Check `client_max_body_size` in nginx.conf |
| Grafana shows no data | Verify Prometheus targets are UP at http://localhost:9091/targets |
| Loki logs not appearing | Check Alloy container: `docker logs alloy` |

### Reset Everything

```bash
docker compose down -v
docker compose up -d
```

## Enabling PostGIS

```bash
docker compose exec db15 bash
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
CREATE EXTENSION IF NOT EXISTS postgis;
```

## First-Time Odoo Installation

```bash
docker compose run --rm odoo17-ssys odoo \
  --db_host=db15 \
  --db_user odoo \
  --db_password $PASSWORD \
  -i base \
  -d odoo17db \
  --stop-after-init
```

## Session Permissions Fix

```bash
docker exec odoo-sales_odoo17-ssys_1 chown -R odoo:odoo /var/lib/odoo/filestore/DATABASE_NAME
```
