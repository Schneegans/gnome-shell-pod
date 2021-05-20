ARG fedora_version=32
FROM fedora:${fedora_version}

RUN dnf update -y &&                                                                     \
    dnf install -y gnome-session-xsession gnome-extensions-app \
                   sudo xorg-x11-server-Xvfb xdotool glib2-devel patch

# Start Xvfb via systemd on display :99.
COPY xvfb@.service /etc/systemd/system
RUN systemctl enable xvfb@:99.service &&                                                 \
    systemctl set-default multi-user.target

# The first is required to make systemd-logind work, the second
# makes sure that the gnomeshell user gets logged in automatically.
RUN mkdir -p /etc/systemd/system/systemd-logind.service.d &&                             \
    { echo "[Service]";                                                                  \
      echo "ProtectHostname=no";                                                         \
    } > /etc/systemd/system/systemd-logind.service.d/override.conf &&                    \
    mkdir -p /etc/systemd/system/console-getty.service.d &&                              \
    { echo "[Service]";                                                                  \
      echo "ExecStart=";                                                                 \
      echo "ExecStart=-/usr/sbin/agetty --autologin gnomeshell --noclear                 \
                                        --keep-baud console 115200,38400,9600 $TERM";    \
    } > /etc/systemd/system/console-getty.service.d/override.conf

# Add the gnomeshell user with no password.
RUN adduser -m -U -G users,adm,wheel gnomeshell &&                                 \
    echo "gnomeshell     ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY gnome-xsession@.service /etc/systemd/user/
RUN sudo -u gnomeshell systemctl enable --user gnome-xsession@:99

# Add the scripts.
COPY enable-extension.sh set-env.sh /home/gnomeshell/

CMD [ "/usr/sbin/init", "systemd.unified_cgroup_hierarchy=0" ]
