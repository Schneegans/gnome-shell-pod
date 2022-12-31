# Changelog of the GNOME Shell Podman Container


## [Version 15](https://github.com/Schneegans/gnome-shell-pod/tree/v15)

**Release Date:** 2022-12-31

#### Changes

* Fedora 37 has been added to the list of images.
* `gnome-terminal` is now included in the images.
* `ImageMagick` and the `find-target.sh` script have been removed.

## [Version 14](https://github.com/Schneegans/gnome-shell-pod/tree/v14)

**Release Date:** 2022-03-06

#### Changes

* The `XDG_SESSION_TYPE` variable is now set for the `gnome-shell` process also in the nested Wayland session.
* The `set-env.sh` script now uses `eval` instead of `exec` which allows executing more complex commands (for example including pipes) in the container.
* Added links to some in-depth guides to the README.
* This changelog was added.
* The default branch was renamed from `master` to `main`.