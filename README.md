# 📦 Run GNOME Shell in a Container!

_:warning: Disclaimer: I have very little to no experience with Docker / Podman. I am sure that many aspects of this project can be improved significantly! Please report any suggestions via [GitHub Issues](https://github.com/Schneegans/gnome-shell-pod/issues)!_

## The Idea

Developing high-quality GNOME Shell extensions is challenging due to various reasons.
One major issues is the lack of continuous integration possibilities.
So I thought: Why not try getting GNOME Shell running on the runners of GitHub Actions?

Of course I know that this is exactly what Podman is not designed to be used for...


## How Does It Work?

The Ubuntu-based image contains `systemd`, `gnome-shell`, `gnome-shell-extension-prefs`, and `xvfb`.
The root user will auto-login via `systemd-logind.service.d` and run `gnome-shell` via `xvfb`.
The framebuffer of `xvfb` is mapped to a file which can be copied to host memory and converted to an image.
This way we can actually make "screenshots" of GNOME-Shell!

## How Do I Use It?

For the following examples you will need to install imagemagick (for converting the xvfb framebuffer image) and, obviously, Podman.
On Ubuntu-like distributions you can install them with this command:

```bash
sudo apt-get install imagemagick podman
```
### Non-Interactive Usage

Use the commands below to start GNOME Shell in the container and capture a screenshot.
There is another example further below which lets you start additional GNOME applications!

```bash
# Run the container in detached mode.
podman run --rm -td ghcr.io/schneegans/gnome-shell:1.0.0

# Wait some time to make sure that GNOME Shell has been started.
sleep 5

# Copy the framebuffer of xvfb.
podman cp $(podman ps -q -l):/opt/Xvfb_screen0 .

# We can stop the container again.
podman stop $(podman ps -q -l)

# Convert it to jpeg.
convert xwd:Xvfb_screen0 capture.jpg

# And finally display the image.
# This way we can see that GNOME Shell is actually up and running!
eog capture.jpg
```



<p align="center">
  <img src ="capture1.jpg" />
</p>

### Interactive Usage

If you want to play around with GNOME Shell inside the pod, use these commands:

```bash
# Run the container in interactive mode. This will automatically login the root user and
# start GNOME Shell in the background. While you will see the output from GNOME Shell,
# you will be able to execute commands from root's shell.
podman run --rm -ti ghcr.io/schneegans/gnome-shell:1.0.0

# For example, you can run this command inside the container:
gnome-control-center

# Now use another terminal on your host to capture and display a screenshot.
# podman cp $(podman ps -q -l):/opt/Xvfb_screen0 . && convert xwd:Xvfb_screen0 capture.jpg && eog capture.jpg

# You can kill the gnome-control-center with Ctrl-C and the poweroff the container.
poweroff
```

<p align="center">
  <img src ="capture2.jpg" />
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
        POD=$(sudo podman run --rm -td ghcr.io/schneegans/gnome-shell:1.0.0)
        sleep 5
        sudo podman cp $POD:/opt/Xvfb_screen0 . && convert xwd:Xvfb_screen0 capture.jpg
        sudo podman stop $POD
    - name: Upload Screenshot
      uses: actions/upload-artifact@v2
      with:
        name: screenshot
        path: capture.jpg
```

## Known Issues

For now, GNOME Shell fails to load any extensions.
This is a pity, but I hope that we will solve this soon!

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
