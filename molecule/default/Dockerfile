ARG MOLECULE_IMAGE=ubuntu:24.04
FROM ${MOLECULE_IMAGE}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-apt \
    sudo \
    systemd \
    systemd-sysv \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Remove unnecessary systemd services
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

VOLUME [ "/sys/fs/cgroup" ]

# NOTE: systemd requires root privileges to manage system services and cgroups
# This is required for Molecule testing of Ansible roles that interact with systemd
# Security: This container is only used for testing and should not run in production
# semgrep: disable[container/missing-user] - systemd requires root to function properly
CMD ["/lib/systemd/systemd"]
