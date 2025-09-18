ARG MOLECULE_IMAGE=ubuntu:24.04
FROM ${MOLECULE_IMAGE}

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3=3.12.3-0ubuntu1 \
    python3-pip=24.0+dfsg-1ubuntu1 \
    python3-apt=2.7.7ubuntu1 \
    sudo=1.9.15p5-3ubuntu5 \
    systemd=255.4-1ubuntu8 \
    systemd-sysv=255.4-1ubuntu8 \
    ca-certificates=20240203 \
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
