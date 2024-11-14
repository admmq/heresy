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

fhs_shell_home=$HOME/Documents/fhs-shell
[ -d $fhs_shell_home ] || mkdir -p $fhs_shell_home

# example guix-fhs-shell python python-numpy
function guix-fhs-shell {
    cd ~
    guix shell --network --container --emulate-fhs \
         --preserve='^DISPLAY$' --preserve='^XAUTHORITY$' --expose=$XAUTHORITY \
         --preserve='^DBUS_' --expose=/var/run/dbus \
         --expose=/sys/dev --expose=/sys/devices --expose=/dev/dri \
         --development ungoogled-chromium \
         bash coreutils curl grep nss-certs gcc-toolchain git node \
         $@ \
         --share=$fhs_shell_home=$HOME
}
