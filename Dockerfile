FROM ubuntu:latest

# Else the installation of GNOME Shell will ask interactively for our time zone.
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y &&                                                       \
    apt-get install systemd gnome-shell gnome-shell-extension-prefs xvfb -y && \
    apt-get clean

# This is required to make systemd-logind work.
RUN mkdir -p /etc/systemd/system/systemd-logind.service.d &&                   \
    { echo "[Service]";                                                        \
      echo "ProtectHostname=no";                                               \
    } > /etc/systemd/system/systemd-logind.service.d/override.conf

# This makes sure that the root user gets logged in automatically.
RUN mkdir -p /etc/systemd/system/console-getty.service.d &&                    \
    { echo "[Service]";                                                        \
      echo "ExecStart=";                                                       \
      echo "ExecStart=-/sbin/getty --autologin root --noclear --keep-baud console 115200,38400,9600 $TERM"; \
    } > /etc/systemd/system/console-getty.service.d/override.conf

# Run GNOME Shell as soon as root logs in. The framebuffer of xvfb will be mapped to /opt/Xvfb_screen0.
RUN echo "xvfb-run --server-args='-ac -screen 0 1600x900x24 -fbdir /opt' gnome-shell &" >> /root/.bashrc
RUN echo "export DISPLAY=:99" >> /root/.bashrc

# Do not attempt to boot into a graphical session.
RUN systemctl set-default multi-user.target

CMD [ "/usr/sbin/init" ]