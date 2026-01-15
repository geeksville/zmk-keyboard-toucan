# Custom geeksville build/setup steps for the "just" tool
# run "apt update; apt install just" to get it

default:
    just --list

# per https://zmk.dev/docs/development/local-toolchain/setup/container
# Then init vscode container per https://zmk.dev/docs/development/local-toolchain/setup/container?container=vsCode
podman-init:
    podman volume create --driver local -o o=bind -o type=none -o device=/home/kevinh/development/keyboard/miryoku_geeksville zmk-config
    podman volume create --driver local -o o=bind -o type=none -o device=/home/kevinh/development/keyboard/modules zmk-modules

# Pull down all the other git repos we need to build locally
git-init:
    cd /workspaces/zmk
    git clone https://github.com/zmkfirmware/zmk.git
    # git clone https://github.com/geeksville/miryoku_geeksville.git    
    mkdir modules
    cd modules
    git clone https://github.com/geeksville/corne-j-geeksville.git

# Instead of this I tried my ubuntu-dev container and ran but it didn't work well
# https://zmk.dev/docs/user-setup (pipx based)
# Then I added the corne-j-geeksville keyboard (eyelash_corne) per those instructions

# This is run INSIDE the vscode devcontainer for zmk, future builds with build will be faster
build-init:  
    #!/usr/bin/env bash
    set -e # Stop on error
    cd /workspaces/zmk
    git checkout v0.3-branch # same as v0.3.0 tag must use this old branch for eyelash_corne currently
    west init -l app/ | true # Initialization
    west update       # Update modules 
    west zephyr-export # Needed to prevent confusing cmake    

# Build for the eyelash_corne with miryoku keymap
build-miryoku: build-init 
    #!/usr/bin/env bash
    set -e # Stop on error
    cd /workspaces/zmk/app
  
    echo "Doing initial build to setup build dirs"
    # -p is important otherwise cmake ignores new -D flags
    # Note: don't add -DCONFIG_ZMK_POINTING=y -DCONFIG_ZMK_DISPLAY=y etc here instead do it in eyelash_corne_left/right_defconfig
    west build -p -d build/eyelash_corne_left -b eyelash_corne_left -- \
        -DZMK_CONFIG=/workspaces/zmk-config/config \
        -DZMK_EXTRA_MODULES=/workspaces/zmk-modules/corne-j-geeksville \
        -DSHIELD=nice_view
    west build -p -d build/eyelash_corne_right -b eyelash_corne_right -- \
        -DZMK_CONFIG=/workspaces/zmk-config/config \
        -DZMK_EXTRA_MODULES=/workspaces/zmk-modules/corne-j-geeksville \
        -DSHIELD=nice_view       
    # Note: When adding multiple modules, make sure they are separated by ;

# Build for the beekeeb toucan
build-toucan: build-init 
    #!/usr/bin/env bash
    set -e # Stop on error
    cd /workspaces/zmk/app
    echo "Doing initial build to setup build dirs"
    # -p is important otherwise cmake ignores new -D flags
    # Note: don't add -DCONFIG_ZMK_POINTING=y -DCONFIG_ZMK_DISPLAY=y etc here instead do it in eyelash_corne_left/right_defconfig
    west build -p -d build/toucan_left -b seeeduino_xiao_ble -S studio-rpc-usb-uart -- \
        -DZMK_CONFIG=/workspaces/zmk-modules/zmk-keyboard-toucan \
        -DSHIELD="toucan_left rgbled_adapter nice_view_gem" \
        -DZMK_EXTRA_MODULES="/workspaces/zmk-modules/zmk-rgbled-widget"\
        -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_SLEEP=y -DCONFIG_ZMK_PM_SOFT_OFF=y
    west build -p -d build/toucan_right -b seeeduino_xiao_ble -- \
        -DZMK_CONFIG=/workspaces/zmk-modules/zmk-keyboard-toucan \
        -DSHIELD="toucan_right rgbled_adapter" \
        -DZMK_EXTRA_MODULES="/workspaces/zmk-modules/zmk-rgbled-widget;/workspaces/zmk-modules/cirque-input-module" \
        -DCONFIG_ZMK_SLEEP=y -DCONFIG_ZMK_PM_SOFT_OFF=y

build:
    #!/usr/bin/env bash
    set -e # Stop on error
    # -DSHIELD=kyria_left 
    cd /workspaces/zmk/app
    west build -d build/left
    west build -d build/right
    find /workspaces/zmk/app -name \*.uf2  

extra:
    sudo apt install python3 libglib2.0-dev pipx
    pipx install keymap-drawer

keymap:
    # keymap parse -z /workspaces/zmk-modules/corne-j-geeksville/config/eyelash_corne.keymap >/tmp/keymap2.yaml
    ~/.local/bin/keymap parse -z /workspaces/zmk-config/config/eyelash_corne.keymap >/tmp/keymap.yaml
    # We don't actually use that parsed version yet, instead use a canned example from
    # https://github.com/caksoylar/keymap-drawer/tree/main/examples
    # ~/.local/bin/keymap dump-config >/workspaces/zmk-config/drawer/my_config.yaml     
    #~/.local/bin/keymap -c /workspaces/zmk-config/drawer/my_config.yaml draw /workspaces/zmk-config/drawer/miryoku.yaml -o workspaces/zmk-config/drawer/miryoku-all.svg
    # Or limit to a single layer
    #~/.local/bin/keymap -c /workspaces/zmk-config/drawer/my_config.yaml draw /workspaces/zmk-config/drawer/miryoku.yaml -s Num -o workspaces/zmk-config/drawer/miryoku-num.svg
    keymap draw /tmp/keymap.yaml -o ./geeksville/eyelash-miryoku.svg