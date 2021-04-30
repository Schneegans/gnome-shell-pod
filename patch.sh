#!/bin/bash

# Exit on error.
set -e

# Go to the location of this script.
cd "$( cd "$( dirname "$0" )" && pwd )"

RESOURCE="/usr/share/gnome-shell/org.gnome.Shell.Extensions.src.gresource"

FILES=$(gresource list $RESOURCE)

for FILE in $FILES
do
    mkdir -p "$(pwd)/extract${FILE%/*}"
    gresource extract $RESOURCE $FILE > "$(pwd)/extract${FILE}"
done

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
cp org.gnome.Shell.Extensions.src.gresource /usr/share/gnome-shell

rm -r extract org.gnome.Shell.Extensions.src.gresource org.gnome.Shell.Extensions.src.xml