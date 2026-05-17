#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]; then
    echo "must be run with sudo"
    exit 1
fi

if command -v go &> /dev/null; then
    echo "golang found"
else
    echo "golang was not found"
fi

DEBUG=true
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if $DEBUG; then

    # set -x

    echo ""
    echo "DEBUG INFO"
    echo "============================="
    echo "script directory: $SCRIPT_DIR"
    echo "============================="
    echo ""
fi

function setup {
    cp -v $SCRIPT_DIR/res/motd.txt /etc/motd

    mirrors_ru

    apk add go make git build-base linux-headers bash iptables iproute2 systemd-resolved
}

function install_amneziawg_go {
    if command -v amneziawg-go &> /dev/null; then
        echo "amneziawg-go is already installed"
        return
    else
        (
            cd /tmp
            git clone https://github.com/amnezia-vpn/amneziawg-go.git
            cd amneziawg-go
            git checkout f4f4c999267437c3eb909e8d0e5278fb4596d9a7
            make

            sudo cp amneziawg-go /usr/bin/
        )
    fi
}

function install_amneziawg_tools {
    if command -v awg &> /dev/null; then
        echo "awg is already installed"
        return
    else
        (
            cd /tmp
            git clone https://github.com/amnezia-vpn/amneziawg-tools.git
            cd amneziawg-tools/src
            git checkout 5d6179a6d0842e98dfb349c28cf1bd8e4b9d1079
            make

            cp wg /usr/bin/awg
            cp wg-quick/linux.bash /usr/bin/awg-quick
            chmod +x /usr/bin/awg /usr/bin/awg-quick

            mkdir -p /etc/amnezia/amneziawg/
        )
    fi
}

function install_webtunnel {
    if command -v webtunnel &> /dev/null; then
        echo "webtunnel is already installed"
        return
    else
        (
            cd /tmp
            git clone https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/webtunnel.git
            cd webtunnel/main/client
            git checkout 382e620edbd960221c68e5468a8015bd5e04328b
            go build
            cp -v ./client /usr/local/bin/webtunnel
        )
    fi
}

function mirrors_ru {
    cp -v $SCRIPT_DIR/res/repositories-ru.txt /etc/apk/repositories
}

function mirrors_not_ru {
    cp -v $SCRIPT_DIR/res/repositories-not-ru.txt /etc/apk/repositories
}

function vpn_up {
    WG_QUICK_USERSPACE_IMPLEMENTATION=amneziawg-go awg-quick up $1
}

function vpn_down {
    WG_QUICK_USERSPACE_IMPLEMENTATION=amneziawg-go awg-quick down $1
}

function vpn_ls {
    ls -al /etc/amnezia/amneziawg/
}

$1 $2
