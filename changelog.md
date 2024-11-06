# Changelog of the GNOME Shell Podman Container

## [Version 19](https://github.com/Schneegans/gnome-shell-pod/tree/v19)

**Release Date:** 2024-11-06

#### Changes

- Fedora 41 has been added to the list of images.
- `xorg-x11-xinit` is now installed explicitly in the images as Fedora 41 does not include it anymore by default.
- The images for Fedora 36, 37, and 38 are not rebuilt anymore. They are still available, but they are not updated anymore.

## [Version 18](https://github.com/Schneegans/gnome-shell-pod/tree/v18)

**Release Date:** 2024-02-25

#### Changes

- Fedora 40 has been added to the list of images.
- The images for Fedora 32, 33, 34, and 35 are not rebuilt anymore. They are still available, but they are not updated anymore.

## [Version 17](https://github.com/Schneegans/gnome-shell-pod/tree/v17)

**Release Date:** 2023-11-09

#### Changes

- Fedora 39 has been added to the list of images.

## [Version 16](https://github.com/Schneegans/gnome-shell-pod/tree/v16)

**Release Date:** 2023-04-01

#### Changes

- Fedora 38 has been added to the list of images.
- There is now a `gnome-shell-pod-rawhide` container which is based on Fedora Rawhide an automatically rebuilt each week.

## [Version 15](https://github.com/Schneegans/gnome-shell-pod/tree/v15)

**Release Date:** 2022-12-31

#### Changes

- Fedora 37 has been added to the list of images.
- `gnome-terminal` is now included in the images.
- `ImageMagick` and the `find-target.sh` script have been removed.

## [Version 14](https://github.com/Schneegans/gnome-shell-pod/tree/v14)

**Release Date:** 2022-03-06

#### Changes

- The `XDG_SESSION_TYPE` variable is now set for the `gnome-shell` process also in the nested Wayland session.
- The `set-env.sh` script now uses `eval` instead of `exec` which allows executing more complex commands (for example including pipes) in the container.
- Added links to some in-depth guides to the README.
- This changelog was added.
- The default branch was renamed from `master` to `main`.
