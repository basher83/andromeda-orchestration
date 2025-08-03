# Nomad Storage Implementation Patterns

This document provides practical implementation patterns and code examples for each Nomad storage type, organized by common use cases.

## Pattern 1: Database Storage

### MySQL/MariaDB with Static Host Volume

```hcl
job "mysql" {
  datacenters = ["dc1"]
  type = "service"
  
  group "database" {
    count = 1
    
    # Static host volume for data persistence
    volume "mysql-data" {
      type      = "host"
      source    = "mysql-data"  # Matches client config
      read_only = false
    }
    
    network {
      port "mysql" {
        static = 3306
        to     = 3306
      }
    }
    
    task "mysql" {
      driver = "docker"
      
      config {
        image = "mariadb:10.11"
        ports = ["mysql"]
      }
      
      volume_mount {
        volume      = "mysql-data"
        destination = "/var/lib/mysql"
      }
      
      env {
        MYSQL_ROOT_PASSWORD = "{{ keyOrDefault \"mysql/root_password\" \"\" }}"
        MYSQL_DATABASE      = "app_db"
      }
      
      resources {
        cpu    = 500
        memory = 1024
      }
      
      service {
        name = "mysql"
        port = "mysql"
        
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
```

### PostgreSQL with Backup Sidecar

```hcl
job "postgresql" {
  datacenters = ["dc1"]
  
  group "database" {
    volume "postgres-data" {
      type   = "host"
      source = "postgres-data"
    }
    
    volume "postgres-backup" {
      type   = "host"
      source = "postgres-backup"
    }
    
    task "postgres" {
      driver = "docker"
      
      config {
        image = "postgres:15"
      }
      
      volume_mount {
        volume      = "postgres-data"
        destination = "/var/lib/postgresql/data"
      }
      
      volume_mount {
        volume      = "postgres-backup"
        destination = "/backup"
      }
    }
    
    task "backup" {
      driver = "docker"
      
      config {
        image = "postgres:15"
        command = "/scripts/backup.sh"
      }
      
      template {
        data = <<EOF
#!/bin/bash
while true; do
  PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
    -h localhost -U postgres -d myapp \
    > /backup/myapp-$(date +%Y%m%d-%H%M%S).sql
  
  # Keep only last 7 days
  find /backup -name "*.sql" -mtime +7 -delete
  
  sleep 86400  # Daily backup
done
EOF
        destination = "local/scripts/backup.sh"
        perms       = "755"
      }
      
      volume_mount {
        volume      = "postgres-backup"
        destination = "/backup"
      }
    }
  }
}
```

## Pattern 2: Application Cache with Ephemeral Storage

### Redis Cache

```hcl
job "redis-cache" {
  datacenters = ["dc1"]
  
  group "cache" {
    count = 3  # Multiple instances for HA
    
    task "redis" {
      driver = "docker"
      
      config {
        image = "redis:7-alpine"
        args  = ["redis-server", "/local/redis.conf"]
      }
      
      # Ephemeral disk for cache data
      ephemeral_disk {
        size    = 2048  # 2GB
        migrate = false # Don't preserve on reschedule
        sticky  = false # Fresh cache on updates
      }
      
      template {
        data = <<EOF
maxmemory 1gb
maxmemory-policy allkeys-lru
save ""  # Disable persistence
dir /alloc/data
EOF
        destination = "local/redis.conf"
      }
      
      resources {
        cpu    = 100
        memory = 1024
      }
    }
  }
}
```

### Build Cache with Cleanup

```hcl
job "build-cache" {
  datacenters = ["dc1"]
  
  group "cache" {
    task "cache-server" {
      driver = "docker"
      
      config {
        image = "nginx:alpine"
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf:ro"
        ]
      }
      
      ephemeral_disk {
        size    = 10240  # 10GB
        migrate = false
        sticky  = true   # Preserve cache between updates
      }
      
      template {
        data = <<EOF
events {}
http {
  proxy_cache_path /alloc/data/cache levels=1:2 
    keys_zone=build_cache:100m max_size=10g inactive=7d;
  
  server {
    listen 8080;
    location / {
      proxy_cache build_cache;
      proxy_pass http://upstream;
    }
  }
}
EOF
        destination = "local/nginx.conf"
      }
      
      # Periodic cleanup task
      template {
        data = <<EOF
#!/bin/sh
find /alloc/data/cache -type f -mtime +7 -delete
EOF
        destination = "local/cleanup.sh"
        perms       = "755"
        change_mode = "noop"
      }
      
      # Run cleanup daily
      artifact {
        source = "local/cleanup.sh"
        destination = "local/cron.d/cleanup"
      }
    }
  }
}
```

## Pattern 3: Stateful Applications with CSI

### GitLab with NFS CSI

```hcl
# First, register the CSI volume
resource "nomad_csi_volume" "gitlab_data" {
  plugin_id    = "nfs"
  volume_id    = "gitlab-data"
  name         = "gitlab-data"
  capacity_min = "100GiB"
  capacity_max = "500GiB"
  
  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }
  
  parameters = {
    server = "nfs.example.com"
    share  = "/exports/gitlab"
  }
}

# GitLab job using CSI volume
job "gitlab" {
  datacenters = ["dc1"]
  
  group "gitlab" {
    # CSI volume for shared data
    volume "data" {
      type      = "csi"
      source    = "gitlab-data"
      read_only = false
      
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }
    
    task "gitlab" {
      driver = "docker"
      
      config {
        image = "gitlab/gitlab-ce:latest"
      }
      
      volume_mount {
        volume      = "data"
        destination = "/var/opt/gitlab"
      }
    }
    
    task "runner" {
      driver = "docker"
      
      config {
        image = "gitlab/gitlab-runner:latest"
      }
      
      # Runners also access shared data
      volume_mount {
        volume      = "data"
        destination = "/var/opt/gitlab"
        read_only   = true
      }
    }
  }
}
```

### Nextcloud with Multiple Storage Types

```hcl
job "nextcloud" {
  datacenters = ["dc1"]
  
  group "nextcloud" {
    # Database on host volume
    volume "db" {
      type   = "host"
      source = "nextcloud-db"
    }
    
    # User files on CSI for sharing
    volume "files" {
      type   = "csi"
      source = "nextcloud-files"
      
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }
    
    task "postgres" {
      driver = "docker"
      
      config {
        image = "postgres:15-alpine"
      }
      
      volume_mount {
        volume      = "db"
        destination = "/var/lib/postgresql/data"
      }
    }
    
    task "nextcloud" {
      driver = "docker"
      
      config {
        image = "nextcloud:27"
      }
      
      volume_mount {
        volume      = "files"
        destination = "/var/www/html/data"
      }
      
      # Ephemeral disk for temp files
      ephemeral_disk {
        size = 5120  # 5GB for uploads/processing
      }
      
      env {
        NEXTCLOUD_DATA_DIR = "/var/www/html/data"
        UPLOAD_TMP_DIR     = "/alloc/data/tmp"
      }
    }
  }
}
```

## Pattern 4: Dynamic Host Volumes for Metrics

### Prometheus with Dynamic Storage

```hcl
job "prometheus" {
  datacenters = ["dc1"]
  
  group "monitoring" {
    count = 1
    
    # Request dynamic volume
    volume "prometheus-data" {
      type   = "host"
      source = "dynamic-data"
      
      # Request specific size
      volume_options {
        size = "50GB"
      }
    }
    
    task "prometheus" {
      driver = "docker"
      
      config {
        image = "prom/prometheus:latest"
        args = [
          "--storage.tsdb.path=/prometheus",
          "--storage.tsdb.retention.time=30d",
          "--storage.tsdb.retention.size=45GB"
        ]
      }
      
      volume_mount {
        volume      = "prometheus-data"
        destination = "/prometheus"
      }
      
      template {
        data = <<EOF
global:
  scrape_interval: 15s
  
scrape_configs:
  - job_name: 'nomad'
    consul_sd_configs:
      - server: '{{ env "CONSUL_HTTP_ADDR" }}'
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job
EOF
        destination = "local/prometheus.yml"
      }
    }
  }
}
```

## Pattern 5: Migration Between Storage Types

### Progressive Migration Job

```hcl
job "migrate-storage" {
  type = "batch"
  
  parameterized {
    payload       = "optional"
    meta_required = ["source_volume", "target_volume", "service_name"]
  }
  
  group "migrate" {
    task "migrate" {
      driver = "raw_exec"
      
      config {
        command = "/usr/local/bin/migrate-storage.sh"
      }
      
      template {
        data = <<EOF
#!/bin/bash
set -euo pipefail

SOURCE="${NOMAD_META_source_volume}"
TARGET="${NOMAD_META_target_volume}"
SERVICE="${NOMAD_META_service_name}"

echo "Starting migration for $SERVICE"
echo "Source: $SOURCE"
echo "Target: $TARGET"

# Stop the service
nomad job stop "$SERVICE"

# Wait for shutdown
sleep 10

# Sync data
rsync -avP "$SOURCE/" "$TARGET/"

# Update job specification
sed -i "s|$SOURCE|$TARGET|g" "/nomad/jobs/$SERVICE.nomad"

# Restart service with new volume
nomad job run "/nomad/jobs/$SERVICE.nomad"

echo "Migration completed"
EOF
        destination = "local/migrate-storage.sh"
        perms       = "755"
      }
    }
  }
}
```

## Pattern 6: Backup and Restore

### Automated Backup Job

```hcl
job "backup-volumes" {
  type = "periodic"
  
  periodic {
    cron             = "0 2 * * *"  # 2 AM daily
    prohibit_overlap = true
  }
  
  group "backup" {
    # Mount all volumes to backup
    volume "source" {
      type      = "host"
      source    = "all-volumes"
      read_only = true
    }
    
    volume "backup-destination" {
      type   = "csi"
      source = "backup-storage"
    }
    
    task "backup" {
      driver = "docker"
      
      config {
        image = "restic/restic:latest"
        command = "backup"
        args = [
          "--repo", "/backup",
          "--host", "${node.unique.name}",
          "/source"
        ]
      }
      
      volume_mount {
        volume      = "source"
        destination = "/source"
        read_only   = true
      }
      
      volume_mount {
        volume      = "backup-destination"
        destination = "/backup"
      }
      
      template {
        data = "{{ keyOrDefault \"backup/restic_password\" \"\" }}"
        destination = "secrets/restic_password"
      }
      
      env {
        RESTIC_PASSWORD_FILE = "${NOMAD_SECRETS_DIR}/restic_password"
      }
    }
  }
}
```

## Best Practices Summary

1. **Choose the Right Storage Type**
   - Ephemeral: Cache, temp files, logs
   - Static Host: Databases, single-node apps
   - Dynamic Host: Per-allocation persistent data
   - CSI: Multi-node access, advanced features

2. **Security Considerations**
   - Always set appropriate permissions
   - Use volume encryption for sensitive data
   - Implement access controls

3. **Performance Optimization**
   - Use local storage for high IOPS
   - Consider SSD for databases
   - Implement caching layers

4. **Backup Strategy**
   - Regular automated backups
   - Test restore procedures
   - Off-site backup storage

5. **Monitoring**
   - Track disk usage
   - Monitor I/O performance
   - Alert on failures

## Troubleshooting Guide

### Volume Mount Failures

```bash
# Check allocation status
nomad alloc status <alloc-id>

# Inspect volume configuration
nomad alloc status -json <alloc-id> | jq '.TaskResources[].Devices'

# Check host volume paths
ls -la /opt/nomad/volumes/

# Verify permissions
stat /opt/nomad/volumes/<volume-name>
```

### CSI Issues

```bash
# Check plugin status
nomad plugin status

# List CSI volumes
nomad volume status

# Inspect specific volume
nomad volume status <volume-id>

# Check plugin allocations
nomad job status <csi-plugin-job>
```

### Performance Problems

```bash
# Check I/O statistics
iostat -x 1

# Monitor specific volume
iotop -o

# Check disk usage
df -h /opt/nomad/volumes/*

# Analyze slow queries (for databases)
docker exec <container> mysql -e "SHOW PROCESSLIST"
```