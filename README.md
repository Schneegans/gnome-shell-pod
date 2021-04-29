# 📦 Run GNOME Shell in a Container!

_:warning: Disclaimer: I have very little to no experience with Docker / Podman. I am sure that many aspects of this project can be improved significantly! Please report any suggestions via [GitHub Issues](https://github.com/Schneegans/gnome-shell-pod/issues)!_

## The Idea

Developing high-quality GNOME Shell extensions is challenging due to various reasons.
One major issues is the lack of continuous integration possibilities.
So I thought: Why not try getting GNOME Shell running on the runners of GitHub Actions?
Of course I know that this is exactly what Podman is not designed to be used for...

**Anyway, here is what already works:**
- [x] Multiple containers for various GNOME Shell versions:
  - [x] 3.36.7 (based on Ubuntu 20.04)
  - [x] 3.38.2 (based on Ubuntu 20.10)
  - [x] 40.0 (based on Ubuntu 21.04)
- [x] GNOME Shell runs automatically when the container is started.
- [x] You can launch other applications, such as `gnome-control-center`.
- [x] You can make "screenshots" of GNOME Shell and transfer them to host memory.
- [x] You can install a GNOME Shell extension from host memory and enable it.
- [x] You can use `xdotool` to interact with the extension.
- [x] All of this works locally and on the GitHub hosted runners!


## How Does It Work?

The Ubuntu-based image contains `systemd`, `gnome-shell`, `gnome-shell-extension-prefs`, `xvfb`, and `xdotool`.
A user called "gnomeshell" will auto-login via `systemd-logind.service.d` and run `gnome-shell` via `xvfb`.
The framebuffer of `xvfb` is mapped to a file which can be copied to host memory and converted to an image.
This way we can actually make "screenshots" of GNOME Shell!

### Why Ubuntu?

Well, I really tried to get a more "native" GNOME Shell running, but [Fedora uses cgroup v2](https://www.redhat.com/sysadmin/fedora-31-control-group-v2) which makes it impossible (or at least very difficult) to run `systemd` in the container on an Ubuntu host. As I want this to be working on GitHub's runners, this is a problem. My second attempt, Arch Linux, failed due to some [`glibc` issues](https://bugs.archlinux.org/task/69563).

Luckily, the Ubuntu versions map quite nicely to the GNOME versions. Nevertheless, I still want to try to switch to Arch or Fedora in the future. This is desireable as it promises more update-to-date GNOME Shell versions.

## How Do I Use It?

For the following examples you will need to install imagemagick (for converting the xvfb framebuffer image) and, obviously, Podman.
On Ubuntu-like distributions you can install them with this command:

```bash
sudo apt-get install imagemagick podman
```

### Basic Usage

If you want to play around with GNOME Shell inside the pod, use these commands:

```bash
# Run the container in interactive mode. This will automatically login the root user and
# start GNOME Shell in the background. While you will see the output from GNOME Shell,
# you will be able to execute commands from an interactive shell.
podman run --rm -ti ghcr.io/schneegans/gnome-shell-3.38:latest

# For example, you can run this command inside the container:
gnome-control-center
```

Now use another terminal on your host to capture and display a screenshot.

```bash
# Copy the framebuffer of xvfb.
podman cp $(podman ps -q -n 1):/home/gnomeshell/Xvfb_screen0 .

# Convert it to jpeg.
convert xwd:Xvfb_screen0 capture.jpg

# And finally display the image.
# This way we can see that GNOME Shell is actually up and running!
eog capture.jpg
```

<p align="center">
  <img src="pictures/capture2.jpg" />
</p>

You can kill the `gnome-control-center` with <kbd>Ctrl</kbd>-<kbd>C</kbd> in the container and then poweroff the container with `poweroff`.


### Detached Mode

Use the commands below to start a non-interactive container and capture a screenshot.

```bash
# Run the container in detached mode.
podman run --rm -td ghcr.io/schneegans/gnome-shell-3.38:latest

# Wait some time to make sure that GNOME Shell has been started.
sleep 5

# Now make a screenshot and show it!
podman cp $(podman ps -q -n 1):/home/gnomeshell/Xvfb_screen0 . && \
       convert xwd:Xvfb_screen0 capture.jpg && \
       eog capture.jpg

# Now we can stop the container again.
podman stop $(podman ps -q -n 1)
```

<p align="center">
  <img src="pictures/capture1.jpg" />
</p>


### Running Commands in Detached Mode

In this example we will install some images inside the container and make GNOME Shell use one of them as background image.
The `gnomeshell` user can run passwordless `sudo`, so you can simply install packages.
`podman exec --user gnomeshell` can be used to run arbitrary commands inside the running container. However, many commands interacting with GNOME Shell will require a connection to the D-Bus. To make this easier, the images contain a `/home/gnomeshell/set-env.sh` script, which sets all required environment variables.

```bash
# Run the container in detached mode.
podman run --rm -td ghcr.io/schneegans/gnome-shell-3.38:latest

# Wait some time to make sure that GNOME Shell has been started.
sleep 5

# Install the gnome-backgrounds package.
podman exec --user gnomeshell $(podman ps -q -n 1) sudo apt install gnome-backgrounds

# Set GNOME Shell's background image. This requires a D-Bus connection,
# so we wrap the command in the set-env.sh script.
podman exec --user gnomeshell $(podman ps -q -n 1) /home/gnomeshell/set-env.sh \
       gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/gnome/adwaita-day.jpg"

# Now make a screenshot and show it!
podman cp $(podman ps -q -n 1):/home/gnomeshell/Xvfb_screen0 . && \
       convert xwd:Xvfb_screen0 capture.jpg && \
       eog capture.jpg

# Now we can stop the container again.
podman stop $(podman ps -q -n 1)
```

<p align="center">
  <img src="pictures/capture5.jpg" />
</p>


### Testing an Extension

In this example, we will start the container, install and enable an extension from extensions.gnome.org and finally create a screenshot.
Enabling the extension involves restarting GNOME Shell.
To simplify this process, another script (`/home/gnomeshell/enable-extension.sh`) is contained in the images.

```bash
# Run the container in detached mode.
podman run --rm -td ghcr.io/schneegans/gnome-shell-3.38:latest

# Wait some time to make sure that GNOME Shell has been started.
sleep 5

# Download an extension.
wget https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v40.shell-extension.zip

# Rename it to UUID.zip. This is expected by the enable-extension.sh script.
mv dash-to-paneljderose9.github.com.v40.shell-extension.zip \
   dash-to-panel@jderose9.github.com.zip

# Copy the archive to the container.
podman cp dash-to-panel@jderose9.github.com.zip $(podman ps -q -n 1):/home/gnomeshell/

# Execute the install script. This installs the extension, restarts GNOME Shell and
# finally enables the extension.
podman exec --user gnomeshell --workdir /home/gnomeshell $(podman ps -q -n 1) ./set-env.sh \
       ./enable-extension.sh dash-to-panel@jderose9.github.com

# Wait some time to make sure that GNOME Shell has been restarted.
sleep 2

# Then make a "screenshot" and display the image.
podman cp $(podman ps -q -n 1):/home/gnomeshell/Xvfb_screen0 . && \
      convert xwd:Xvfb_screen0 capture.jpg && \
      eog capture.jpg

# Finally stop the container.
podman stop $(podman ps -q -n 1)
```

<p align="center">
  <img src="pictures/capture4.jpg" />
</p>

### Interacting with GNOME Shell

If you started the container in detached mode, you can execute commands inside the container using `podman exec`. In this example we will use `xdotool` to simulate mouse input.

```bash
# Run the container in detached mode.
podman run --rm -td ghcr.io/schneegans/gnome-shell-3.38:latest

# Wait some time to make sure that GNOME Shell has been started.
sleep 5

# Click the activities button.
podman exec --user gnomeshell --workdir /home/gnomeshell $(podman ps -q -n 1) ./set-env.sh \
       xdotool mousemove 10 10 click 1 && sleep 1

# Click the applications grid button.
podman exec --user gnomeshell --workdir /home/gnomeshell $(podman ps -q -n 1) ./set-env.sh \
       xdotool mousemove 50 550 click 1 && sleep 1

# Then make a "screenshot" and display the image.
podman cp $(podman ps -q -n 1):/home/gnomeshell/Xvfb_screen0 . && \
       convert xwd:Xvfb_screen0 capture.jpg && \
       eog capture.jpg

# Finally stop the container.
podman stop $(podman ps -q -n 1)
```

<p align="center">
  <img src="pictures/capture3.jpg" />
</p>

### Using This in a GitHub Action

When you try to use this container in a GitHub actions workflow, you will need to run podman with `sudo` (for whatever reason).
But it works! Once the workflow run is finished, you can download the screenshot as artifact.

```yaml
name: Tests

on:
  push:
    branches:
      - '**'
  pull_request:
    branches:
      - '**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Run GNOME Shell
      run: |
        sudo apt-get install imagemagick -qq
        POD=$(sudo podman run --rm -td ghcr.io/schneegans/gnome-shell-3.38:latest)
        sleep 5
        sudo podman cp $POD:/home/gnomeshell/Xvfb_screen0 . && convert xwd:Xvfb_screen0 capture.jpg
        sudo podman stop $POD
    - name: Upload Screenshot
      uses: actions/upload-artifact@v2
      with:
        name: screenshot
        path: capture.jpg
```


## :octocat: Contributing

Commits should start with a Capital letter and should be written in present tense (e.g. __:tada: Add cool new feature__ instead of __:tada: Added cool new feature__).
You should also start your commit message with **one** applicable emoji.
This does not only look great but also makes you rethink what to add to a commit. Make many but small commits!

Emoji | Description
------|------------
:tada: `:tada:` | When you added a cool new feature.
:wrench: `:wrench:` | When you added a piece of code.
:art: `:art:` | When you improved / added assets like themes.
:rocket: `:rocket:` | When you improved performance.
:memo: `:memo:` | When you wrote documentation.
:beetle: `:beetle:` | When you fixed a bug.
:twisted_rightwards_arrows: `:twisted_rightwards_arrows:` | When you merged a branch.
:fire: `:fire:` | When you removed something.
:truck: `:truck:` | When you moved / renamed something.
