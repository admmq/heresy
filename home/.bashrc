# Bash initialization for interactive non-login shells and
# for remote shells (info "(bash) Bash Startup Files").

# Export 'SHELL' to child processes.  Programs such as 'screen'
# honor it and otherwise use /bin/sh.
export SHELL

if [[ $- != *i* ]]
then
    # We are being invoked from a non-interactive shell.  If this
    # is an SSH session (as in "ssh host command"), source
    # /etc/profile so we get PATH and other essential variables.
    [[ -n "$SSH_CLIENT" ]] && source /etc/profile

    # Don't do anything else.
    return
fi

# Source the system-wide file.
[ -f /etc/bashrc ] && source /etc/bashrc

alias ls='ls -p --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'
alias ip='ip -color=auto'

# example:
# guix-fhs-shell python python-numpy
function heresy-guix-fhs-shell {
    fhs_shell_home=$HOME/FHS
    [ -d $fhs_shell_home ] || mkdir -p $fhs_shell_home

    cd ~
    guix shell --network --container --emulate-fhs \
         --preserve='^XDG_|^WAYLAND_DISPLAY$' --preserve='^DISPLAY$' \
         --expose=/dev/dri \
         --share=/tmp/.X11-unix/ \
         --expose=/run/user/$UID \
         --preserve='^DBUS_'\
         --expose=/var/run/dbus \
         --development ungoogled-chromium \
         bash coreutils curl grep nss-certs gcc-toolchain git node \
         $@ \
         --share=$fhs_shell_home=$HOME
}

# example:
# heresy-run-tor "15.235.48.110:6241 16AE419DBE20765A30E27008E1359DBDBAD260E1 cert=gRpsUldyaLSeBI51nMWcu55dwdD8YJ0N6DQJZxugFS995I+c24PtAaJVy1sfc+fnTvZcGQ" "37.59.26.110:19706 A633763DAE52CB625D5D2C61C719449C2AB510F2 cert=LvggKZHapvNlZPI7GN19q8OWBMuYtxkRnpvwjEfGI2rh14Vp4UsZnnzJa1dftIRgct4tNA"
function heresy-run-tor {
    torrc_location="/tmp/torrc"
    bridge1=$1
    bridge2=$2

    heresy-create-torrc-file $torrc_location "$bridge1" "$bridge2"

    tor -f $torrc_location
}

function heresy-create-torrc-file {
    torrc_location=$1
    bridge1=$2
    bridge2=$3
    obfs4proxy="$(guix build go-github-com-operatorfoundation-obfs4)/bin/obfs4proxy"

    [[ -f $torrc_location ]] && rm $torrc_location
    cat <<EOF >>$torrc_location
UseBridges 1 
ClientTransportPlugin obfs4 exec $obfs4proxy
Bridge obfs4 $bridge1 iat-mode=0
Bridge obfs4 $bridge2 iat-mode=0
EOF
}

function heresy-build-all-packages {
    guix build $(guix package -A | awk '{ print $1 "@" $2 }')
}

function heresy-generate-ssh-keys {
    ssh-keygen -t ed25519
}

function heresy-data-backup {
    today=$(date +'%m-%d-%y')

    cd ~ \
        && mkdir -v ./backup \
        && cp -rv ./Documents ./backup \
        && cp -rv ./Music ./backup \
        && cp -rv ./Sources ./backup \
        && cp -rv ./Videos ./backup \
        && tar -cvzf ./$today-backup.tar.gz ./backup/ \
        && rm -rfv ./backup
}

function heresy-data-delete {
    cd ~
    rm -rfv ./Documents
    rm -rfv ./Music
    rm -rfv ./Sources
    rm -rfv ./Videos
}

function heresy-data-restore {
    data_archive=$1

    if [[ $# -ne 1 ]]; then
        echo 'Too many/few arguments, expecting one' >&2
        exit 1
    fi

    cd ~ \
        && tar -xvzf ./$data_archive \
        && mv ./backup/Documents/ . \
        && mv ./backup/Music/ . \
        && mv ./backup/Sources/ . \
        && mv ./backup/Videos/ . \
        && rm -rfv ./backup
}

function heresy-disable-screen-saver-blanking {
    xset s off
}
