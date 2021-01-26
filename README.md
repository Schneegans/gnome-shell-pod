# A Podman container which runs GNOME Shell in xvfb

Some notes:

```bash
podman build -t ghcr.io/schneegans/gnome-shell:1.0.0 .
podman push ghcr.io/schneegans/gnome-shell:1.0.0
podman run --rm -it gnome-shell:1.0.0
podman cp $(podman ps -q -l):/opt/Xvfb_screen0 . && convert xwd:Xvfb_screen0 capture.jpg && eog capture.jpg
podman stop $(podman ps -q -l)

# podman exec -it $(podman ps -q -l) gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/shell/extensions/flypie --method org.gnome.Shell.Extensions.flypie.ShowMenu 'Example Menu'
```