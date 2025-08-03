#!/bin/bash
# Quick script to setup Netdata MySQL/MariaDB monitoring
# Run as root or with sudo

echo "Setting up Netdata access to MariaDB/MySQL..."

# Create the netdata user with minimal privileges
mysql -u root << EOF
-- Create netdata user for different connection methods
CREATE USER IF NOT EXISTS 'netdata'@'localhost';
CREATE USER IF NOT EXISTS 'netdata'@'127.0.0.1';
CREATE USER IF NOT EXISTS 'netdata'@'172.17.0.1';
CREATE USER IF NOT EXISTS 'netdata'@'172.17.%';
CREATE USER IF NOT EXISTS 'netdata'@'%';

-- Grant minimal monitoring privileges
GRANT USAGE, REPLICATION CLIENT, PROCESS ON *.* TO 'netdata'@'localhost';
GRANT USAGE, REPLICATION CLIENT, PROCESS ON *.* TO 'netdata'@'127.0.0.1';
GRANT USAGE, REPLICATION CLIENT, PROCESS ON *.* TO 'netdata'@'172.17.0.1';
GRANT USAGE, REPLICATION CLIENT, PROCESS ON *.* TO 'netdata'@'172.17.%';
GRANT USAGE, REPLICATION CLIENT, PROCESS ON *.* TO 'netdata'@'%';

-- If you have performance_schema enabled
GRANT SELECT ON performance_schema.* TO 'netdata'@'localhost';
GRANT SELECT ON performance_schema.* TO 'netdata'@'127.0.0.1';
GRANT SELECT ON performance_schema.* TO 'netdata'@'172.17.0.1';
GRANT SELECT ON performance_schema.* TO 'netdata'@'172.17.%';

FLUSH PRIVILEGES;

-- Verify users were created
SELECT User, Host FROM mysql.user WHERE User = 'netdata';
EOF

echo "Testing connection as netdata user..."
mysql -u netdata -e "SELECT VERSION();" 2>&1

echo "Creating Netdata MySQL configuration..."
cat > /etc/netdata/go.d/mysql.conf << 'EOF'
jobs:
  - name: local
    dsn: netdata@unix(/run/mysqld/mysqld.sock)/
    
  - name: tcp
    dsn: netdata@tcp(localhost:3306)/
EOF

echo "Restarting Netdata..."
systemctl restart netdata

echo "Done! Check http://localhost:19999 for MySQL metrics"