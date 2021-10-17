# Fedora version (e.g. 32, 33, ...) can be passed using --build-arg=fedora_version=...
ARG fedora_version=latest
FROM registry.fedoraproject.org/fedora:${fedora_version}

# Install required packages.
RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app ImageMagick \
                   xorg-x11-server-Xvfb xdotool xautomation sudo

# Copy system configuration.
COPY etc /etc

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    systemctl --global disable dbus-broker && \
    systemctl --global enable dbus-daemon && \
    adduser -m -U -G users,adm,wheel gnomeshell && \
    echo "gnomeshell     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add the scripts.
COPY bin /usr/local/bin

# dbus port
EXPOSE 1234

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
