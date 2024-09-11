# NVIM
Install ripgrep
```
sudo pacman -S ripgrep
sudo apt install ripgrep
```
Link nvim config with your local config
```
rm -rf ~/.config/nvim
ln -s $PWD/nvim ~/.config/nvim
```
Launch nvim and enjoy

NOTE: If you run `sudo nvim`, then your config won't be loaded
If you'd like you can
```
sudo ln -s $PWD/nvim /root/.config/nvim
```
but this might not be desired (all plugins running wild with root permission)
Much more sensible would be copying of `remap.lua` only
# General
1. ZSH and OMZ
Install ZSH:
```
sudo pacman -S zsh
# or for apt
sudo apt install zsh
```
Install ohmyzsh:
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```


Paste it into .zshrc and follow instruction from comments:
```
export ZSH="$HOME/.oh-my-zsh"
# If you want it to work on terminal without powerline fonts I suggest "avit"
ZSH_THEME="agnoster"
# To make it work:
# sudo apt install command-not-found -y
# or
# sudo pacman -S zsh-syntax-highlighting
# cd ~/.oh-my-zsh/plugins/
# git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
# source ~/.zshrc
# exec zsh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting volta)
source $ZSH/oh-my-zsh.sh
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi
```

2. Install TILIX
[here](https://gnunn1.github.io/tilix-web/)
3. Install Docker and Docker-Compose
```
sudo pacman -S docker docker-compose
# for non-root access to docker
sudo groupadd docker
sudo usermod -aG docker $USER
```
4. AWS CLI
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
5. Volta
```
curl https://get.volta.sh | bash
```
6. Pulsar
```
wget https://archive.apache.org/dist/pulsar/pulsar-2.10.1/DEB/apache-pulsar-client-dev.deb
wget https://archive.apache.org/dist/pulsar/pulsar-2.10.1/DEB/apache-pulsar-client.deb
```
after download use either `debtap` or `dpkg` (depends on package manager)
7. Setup .npmrc file
8. Vesktop for Discord
If you install it on ARCH use `make_searchable.sh`



# For GNOME Arch based
1. Install extensions
* Clipboard history
* Extension List
* Search Light (configure it!!!)
* System Monitor
2. Install bauh
```
sudo pacman -Syu bauh
```
3. Install debtap
```
sudo yay -S debtap
sudo debtap -U
```

# Audio setup

## General

1. You probably want to download [Tidal Hi-Fi](https://github.com/Mastermindzh/tidal-hifi), log in and configure listenbrainz

## Pipewire

NOTE: Pipewire is shit, this config does not work
Never install wireplumber

If you decide to use this you can use `Wayland`

```bash
# Copy template from /usr/share/pipewire
sudo cp /usr/share/pipewire/pipewire.conf /etc/pipewire/pipewire.conf
# Modify the config
sudo nvim /etc/pipewire/pipewire.conf
```

The lines you want to change/uncomment/comment
```
# This should be set to true
settings.check-rate         = true
# This should be commented
# default.clock.rate          = 96000

# Uncommented, containing all sample rates supported by audio output
default.clock.allowed-rates = [ 44100 48000 88200 96000 ]
```

## Pulseaudio

Since `pipewire` is a bitch, which does not want to work

Go to `/etc/pulse/daemon.conf`
```
# Set the following
nice-level = -11
resample-method = soxr-vhq
avoid-resampling = no # tried setting it to yes, had troubles afterwards with audio quality
default-sample-format = float32le
default-sample-rate = 96000
alternate-sample-rate = 44100

# Get rid of this (default.pa in the same directory)
load-module module-suspend-on-idle
```

You may want to set default sink
```
pactl list short sinks
pactl set-default-sink <SINK_NAME_FROM_FIRST_COMMAND>
```

Get rid of `Wayland` - it just doesn't want to work with pulseaudio (tried couple of workarounds, using old x11 is best)

Always make sure that no other audio server is running:
```
# check for pipewire
systemctl --user status pipewire
```
if it does, remove it
```
sudo pacman -Rs pipewire
```
