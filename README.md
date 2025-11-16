# NVIM
Install ripgrep
```
sudo pacman -S ripgrep
sudo apt install ripgrep
```
Install [vivify](https://github.com/jannis-baum/vivify?tab=readme-ov-file) -
it is recommended to use direct download from github package and add it to zshrc
```
export VIVIFY_PATH="/home/czandal/CodeShit/vivify/vivify-linux/"
export PATH="$VIVIFY_PATH:$PATH"
```
Install ziglang from `https://ziglang.org/download/` and it to PATH
```
export ZIG_PATH="/home/czandal/CodeShit/zig/zig-bin"
export PATH="$ZIG_PATH:$PATH"
```
and then clone `https://github.com/zigtools/zls` and build new zls and add it to PATH as well:
```
mkdir -p ~/CodeShit/zig
cd ~/CodeShit/zig
git clone https://github.com/zigtools/zls
cd zls
zig build -Doptimize=ReleaseSafe
```
Update PATH:
```
export ZLS_PATH="/home/czandal/CodeShit/zig/zls/zig-out/bin"
export PATH="$ZLS_PATH:$PATH"
```

Install ollama and pull most used models
```
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:1.5b
ollama pull qwen2.5-coder:3b
ollama pull qwen2.5-coder:7b
ollama pull deepseek-coder-v2:16b
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

## Support of zig debugging
Install `lldb` using package manager
```bash
sudo apt install lldb
sudo pacman -S lldb
```
Install vs-code
```bash
sudo apt install code
sudo pacman -S code
```
Then run it and install extension `codelldb` from Vadim Chugunov
Update your PATH to contain the extension
```bash
export CODE_LLDB_PATH="/home/czandal/.vscode/extensions/vadimcn.vscode-lldb-1.11.5/adapter/"
export PATH="$CODE_LLDB_PATH:$PATH"
```

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

# Load pyenv automatically by appending
# the following to
# ~/.zprofile (for login shells)
# and ~/.zshrc (for interactive shells) :

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Restart your shell for the changes to take effect
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


9. AMD GPU stats


On Arch:
```sh
sudo pacman -S radeontop
```
10. Funny utility to brag how important of a GIT contributor you are


Go to releases of [this](https://github.com/sinclairtarget/git-who/releases) and install it. Here is example:
```
wget https://github.com/sinclairtarget/git-who/releases/download/v1.2/gitwho_v1.2_linux_amd64.tar.gz
# Before effectively installing, check the sum
sha256sum gitwho_v1.2_linux_amd64.tar.gz
# proceed to installation
tar xf gitwho_v1.2_linux_amd64.tar.gz
rm gitwho_v1.2_linux_amd64.tar.gz
sudo mv linux_amd64/git-who /usr/bin/
git-who -l
```

11. Lua version manager `luaver`
```
curl -fsSL https://raw.githubusercontent.com/dhavalkapil/luaver/master/install.sh | sh -s - -r v1.1.0
```
Update `.zshrc` by adding:
```
[ -s ~/.luaver/luaver ] && . ~/.luaver/luaver
[ -s ~/.luaver/completions/luaver.bash ] && . ~/.luaver/completions/luaver.bash
```
Install lua and luarocks
```bash
luaver install 5.1.5
luaver install-luarocks 3.9.2
```
12. Golang installation
```bash
# Go to `https://go.dev/dl/` and pick release
mv ~/Downloads/go1*.tar.gz golang.tar.gz
sha256sum golang.tar.gz
# Check if output is as expected
rm -rf /usr/local/go && sudo tar -C /usr/local -xzf golang.tar.gz
```
Add new lines to `.zshrc`
```bash
export GOLANG_PATH="/usr/local/go/bin"
export PATH="$GOLANG_PATH:$PATH"
```
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
