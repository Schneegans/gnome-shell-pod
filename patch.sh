#!/bin/bash

# -------------------------------------------------------------------------------------- #
# To be able to check whether an extension's preferences dialog can be opened            #
# successfully, it is necessary that the error which is only shown in the user           #
# interface of the gnome-extensions-app is also logged to journalctl.                    #
#                                                                                        #
# This scripts adds one line of JavaScript to GNOME Shell to do this.                    #
# -------------------------------------------------------------------------------------- #

# Exit on error.
set -e

# Go to the location of this script.
cd "$( cd "$( dirname "$0" )" && pwd )"

# This gresource contains the JavaScript file to patch.
RESOURCE="/usr/share/gnome-shell/org.gnome.Shell.Extensions.src.gresource"

# First we extract all contained files to a directory called 'extract'.
FILES=$(gresource list $RESOURCE)
for FILE in $FILES
do
    mkdir -p "$(pwd)/extract${FILE%/*}"
    gresource extract $RESOURCE $FILE > "$(pwd)/extract${FILE}"
done

# Then we add the logging line.
patch --no-backup-if-mismatch -p0 <<'EOF'
--- extract/org/gnome/Shell/Extensions/js/extensionsService.js
+++ extract/org/gnome/Shell/Extensions/js/extensionsService.js
@@ -209,6 +209,7 @@
             this._stack.visible_child = widget;
         } catch (e) {
             this._setError(e);
+            logError(e, 'Failed to open preferences');
         }
     }
EOF

# Then we compile all extracted files to a new gresource file.
FILES=$(find "extract" -type f -printf "%P\n" | xargs -i echo "    <file>{}</file>")
cat <<EOF >"org.gnome.Shell.Extensions.src.xml"
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource>
$FILES
  </gresource>
</gresources>
EOF

cd extract && glib-compile-resources ../org.gnome.Shell.Extensions.src.xml && cd ..

# Last but not least, we copy the newly compiled resource file to its original location.
cp org.gnome.Shell.Extensions.src.gresource /usr/share/gnome-shell

# Finally we delete all temporary files.
rm -r extract org.gnome.Shell.Extensions.src.gresource org.gnome.Shell.Extensions.src.xml