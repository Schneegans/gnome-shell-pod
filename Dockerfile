# Fedora version (e.g. 32, 33, ...) can be passed using --build-arg=fedora_version=...
ARG fedora_version=latest
FROM registry.fedoraproject.org/fedora:${fedora_version}

# Install required packages.
RUN dnf update -y && \
    dnf --nodocs install -y \
        gnome-session-xsession gnome-extensions-app xorg-x11-xinit \
        xorg-x11-server-Xvfb gnome-terminal xdotool xautomation sudo && \
    dnf clean all -y && \
    rm -rf /var/cache/dnf

# Copy system configuration.
COPY etc /etc

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    adduser -m -U -G users,adm gnomeshell && \
    echo "gnomeshell     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add the scripts.
COPY bin /usr/local/bin

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
