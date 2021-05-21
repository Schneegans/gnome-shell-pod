ARG base_image
FROM ${base_image}

RUN sudo -u gnomeshell systemctl enable --user gnome-xsession@:99
