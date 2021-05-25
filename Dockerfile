ARG fedora_version=32
FROM fedora:${fedora_version}

RUN dnf update -y && \
    dnf install -y gnome-session-xsession gnome-extensions-app vte291 libxslt \
                   gtk3-devel gtk4-devel glib2-devel \
                   xorg-x11-server-Xvfb xdotool xautomation \
                   sudo make patch jq unzip git npm
RUN npm install -g eslint

COPY systemd /etc/systemd

# Start Xvfb via systemd on display :99.
# Add the gnomeshell user with no password.
# Unmask required on Fedora 32
RUN systemctl unmask systemd-logind.service console-getty.service getty.target && \
    systemctl enable xvfb@:99.service && \
    systemctl set-default multi-user.target && \
    adduser -m -U -G users,adm,wheel gnomeshell && \
    echo "gnomeshell     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add the scripts.
COPY *.sh /usr/local/bin/

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
