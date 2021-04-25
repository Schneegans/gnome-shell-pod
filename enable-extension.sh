#!/bin/bash

# -------------------------------------------------------------------------------------- #
# This is a little helper script to install and enable a GNOME Shell extension in this   #
# container. It assumes that you have copied your extension package to /home/gnomeshell  #
# and that the package is called <UUID of the extnesion>.zip                             #
#                                                                                        #
# This could be done with the following command:                                         #
# podman cp foo@bar.org.zip $(podman ps -q -n 1):/home/gnomeshell/                       #
#                                                                                        #
# Then you can run this script inside of the container with:                             #
# podman exec --user gnomeshell $(podman ps -q -n 1) /home/gnomeshell/set-env.sh \       #
#              /home/gnomeshell/enable-extension.sh foo@bar.org                          #
# -------------------------------------------------------------------------------------- #

# Exit on error.
set -e

# Check that an argumemt is given.
if [ $# -eq 0 ]
  then
    echo "Please give the zip archive of your extension as parameter!"
    exit 0
fi

# Go to the location of this script.
cd "$( cd "$( dirname "$0" )" && pwd )"

# First install the extension.
gnome-extensions install $1.zip

# Then restart GNOME Shell. We wait some seconds afterwards to make sure that this has
# finished. Is there an easier way to reload newly installed extensions?
echo -n "Restarting GNOME Shell... "
busctl --user call org.gnome.Shell /org/gnome/Shell \
                   org.gnome.Shell Eval s 'Meta.restart("Restarting…")' --quiet
sleep 3
echo "Done."

# Finally enable the extension.
gnome-extensions enable $1