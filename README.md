# Setup
```
git clone https://github.com/Czandal/dev-setup && cd dev-setup
./setup            # menu, pick what you want
./setup nvim mise  # or name it
./setup -n all     # dry run, prints commands only
```
Every script in `scripts/` also runs on its own, asks before each sudo/AUR/rc-file change
and can be rerun safely. Arch first, `apt` where a package exists.

# NVIM
```
./setup nvim
```
Installs ripgrep, tree-sitter-cli, [md-to-pdf](https://github.com/simonhaenisch/md-to-pdf), links
`nvim/` to `~/.config/nvim` (old config is moved to `nvim.bak.<date>`) and restores plugins.
Needs Neovim 0.12+. LSP servers and `codelldb` (zig debugging) come from Mason on first start.

Markdown goes to PDF through puppeteer (system chromium, node from mise): `:MdPdf`, `:MdHtml`
(add `!` to open the result), `:MdPreview` re-renders on every save. `:MdBook` opens it in the browser as a
book (A5, serif, `#` story, `##` chapter, `---` scene break). Look is tuned in `nvim/md-to-pdf/`
(`style.css`, `book.css`), per document in its front-matter.
Paranoid mise may refuse a puppeteer dependency published without provenance; the script then
prints the exemption to add yourself once you have checked that release.

Zig and zls come from mise (below), zls has to match the zig minor version.

NOTE: If you run `sudo nvim`, then your config won't be loaded
If you'd like you can
```
sudo ln -s $PWD/nvim /root/.config/nvim
```
but this might not be desired (all plugins running wild with root permission)
Much more sensible would be copying of `remap.lua` only

## Local models
```
./setup llm
```
Installs ollama, creates `korektor-pl` (correction plugin for Polish, `<leader>b` on a selection)
and installs llama-server. Before running neovim if you'd like some autocompletions start it
(tweak accordingly to the power of your machine):
```sh
llama-server --fim-qwen-3b-default -fa on --port 8012 --batch-size 1024 --cache-reuse 256
```

# General
1. Toolchains: [mise](https://mise.jdx.dev) instead of volta, pyenv, luaver and tarballs
```
./setup mise
```
Paranoid and clean by default: installs no tools, never auto-installs, and loads nothing from a
repo (`mise.toml`, `.env`, `.nvmrc`, ...) until you `mise trust` it, again after every change.
To get my toolchain:
```
mise use -g node@24.3.0 python@3.13.1 go@1.24.2 zig@0.17.1 zls@0.17.0 lua@5.1.5
```
(same as `./setup mise --tools`). Per project: `mise use node@18 && mise trust`.

2. ZSH and OMZ
```
./setup shell
```
zsh, ohmyzsh, autosuggestions and syntax highlighting. Theme is "agnoster", if you want it to
work on terminal without powerline fonts I suggest "avit".

3. Docker, AWS CLI, GPU stats (`amdgpu_top` on AMD, `nvtop` otherwise), Vesktop for Discord and
[git-who](https://github.com/sinclairtarget/git-who), funny utility to brag how important
of a GIT contributor you are (`git-who -l`)
```
./setup tools
```
App missing in the launcher? `scripts/desktop-entry.sh <exec> <name> [comment] [icon]`

4. Pulsar: `npm install pulsar-client` ships its own binaries now. If you still need the C++ client,
it lives [here](https://downloads.apache.org/pulsar/) under `pulsar-client-cpp-*` (use `debtap` or `dpkg`).

# For GNOME Arch based
```
./setup gnome
```
Installs ptyxis (tilix is unmaintained) and debtap. Install extensions yourself:
* Clipboard history
* Extension List
* Search Light (configure it!!!)
* System Monitor

# Audio setup

1. You probably want to download [Tidal Hi-Fi](https://github.com/Mastermindzh/tidal-hifi), log in and configure listenbrainz

## Pipewire
```
./setup audio
# other rates: RATES="44100 48000 96000 192000" ./setup audio
```
Installs pipewire, pipewire-pulse and wireplumber (replaces pulseaudio, it asks first) and writes
`~/.config/pipewire/pipewire.conf.d/10-rates.conf` so the output follows the sample rate of the
track instead of resampling:
```
context.properties = {
    default.clock.allowed-rates = [ 44100 48000 88200 96000 ]
}
```
List every rate your audio output supports. Check with `pw-top` while something plays.

## Pulseaudio

If pipewire does not want to work, go to `/etc/pulse/daemon.conf`
```
nice-level = -11
resample-method = soxr-vhq
avoid-resampling = no # tried setting it to yes, had troubles afterwards with audio quality
default-sample-format = float32le
default-sample-rate = 96000
alternate-sample-rate = 44100
```
and remove `load-module module-suspend-on-idle` from `default.pa` in the same directory.
Only one audio server at a time: `systemctl --user status pipewire pulseaudio`
