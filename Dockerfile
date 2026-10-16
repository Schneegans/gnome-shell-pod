ARG fedora_version=latest
FROM registry.fedoraproject.org/fedora:${fedora_version}

# Install required packages for headless GNOME Shell on Wayland.
RUN dnf --nodocs install -y \
        gnome-shell \
        gnome-session \
        gnome-session-wayland-session \
        gnome-extensions-app \
        gnome-control-center \
        gnome-backgrounds \
        gdm \
        systemd \
        procps \
        sudo \
        mesa-dri-drivers \
        glib2 \
        findutils \
        dconf \
        dbus-daemon \
        GraphicsMagick \
    && dnf remove -y gnome-tour || true \
    && rm -f /etc/xdg/autostart/org.gnome.Tour.desktop /usr/share/applications/org.gnome.Tour.desktop /etc/xdg/autostart/org.gnome.Evolution-alarm-notify.desktop /etc/xdg/autostart/localsearch-3.desktop /etc/xdg/autostart/tracker-miner-fs-3.desktop \
    && dnf clean all -y \
    && rm -rf /var/cache/dnf

# Copy system configuration.
COPY etc /etc

# Mask unused physical display/getty services and enable headless GNOME session for gnomeshell user.
# Switch to dbus-daemon to avoid inotify instance exhaustion (dbus-broker fatal exit -24).
# Add gnomeshell user with no password for sudo.
RUN systemctl unmask systemd-logind.service && \
    systemctl mask \
        gdm.service \
        console-getty.service \
        getty.target \
        NetworkManager.service \
        NetworkManager-wait-online.service \
        rtkit-daemon.service \
        tuned.service \
        tuned-ppd.service \
        geoclue.service && \
    systemctl --force enable dbus-daemon.service && \
    systemctl --global --force enable dbus-daemon.service && \
    systemctl --global mask \
        localsearch-3.service \
        localsearch-control-3.service \
        localsearch-writeback-3.service \
        evolution-source-registry.service \
        evolution-calendar-factory.service \
        evolution-addressbook-factory.service \
        evolution-alarm-notify.service \
        gvfs-udisks2-volume-monitor.service \
        gvfs-afc-volume-monitor.service \
        gvfs-goa-volume-monitor.service \
        pipewire.socket \
        pipewire-pulse.socket \
        pipewire.service \
        pipewire-pulse.service \
        wireplumber.service && \
    echo "GTK_A11Y=none" >> /etc/environment && \
    echo "NO_AT_BRIDGE=1" >> /etc/environment && \
    systemctl set-default multi-user.target && \
    useradd --create-home --shell /bin/bash -G users,wheel gnomeshell && \
    echo "gnomeshell ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    systemctl enable gnome-headless-session@gnomeshell.service && \
    dconf update

# Add helper scripts.
COPY bin /usr/local/bin
RUN chmod +x /usr/local/bin/*.sh

STOPSIGNAL SIGRTMIN+3

CMD [ "/sbin/init" ]
