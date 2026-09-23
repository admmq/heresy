;;; Guix system service for the Amnezia VPN client's privileged helper.

(define-module (heresy amnezia)
  #:use-module (heresy pkgs amnezia)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:export (amnezia-vpn-configuration
            amnezia-vpn-configuration?
            amnezia-vpn-service-type))

;; Upstream ships this as a systemd unit
;; (deploy/data/linux/AmneziaVPN.service):
;;
;;   [Service]
;;   Type=simple
;;   Restart=always
;;   RestartSec=1
;;   ExecStart=/opt/AmneziaVPN/bin/AmneziaVPN-service
;;
;; which this shepherd service mirrors: the binary runs as root and talks
;; to the (unprivileged) GUI client over a fixed-path local socket
;; (/tmp/local:AmneziaVpnIpcInterface, via Qt Remote Objects; see
;; amnezia-client's ipc/ipc.h), not systemd/D-Bus activation, so nothing
;; beyond "keep this process running as root" is required here.

(define-record-type* <amnezia-vpn-configuration>
  amnezia-vpn-configuration make-amnezia-vpn-configuration
  amnezia-vpn-configuration?
  (package amnezia-vpn-configuration-package
           (default amnezia-vpn)))

(define (amnezia-vpn-shepherd-services config)
  (list
   (shepherd-service
    (documentation "Run the Amnezia VPN privileged helper service.")
    (provision '(amnezia-vpn))
    (requirement '(networking))
    (respawn? #t)
    (start #~(make-forkexec-constructor
              (list #$(file-append (amnezia-vpn-configuration-package config)
                                    "/bin/AmneziaVPN-service"))))
    (stop #~(make-kill-destructor)))))

(define amnezia-vpn-service-type
  (service-type
   (name 'amnezia-vpn)
   (extensions
    (list (service-extension shepherd-root-service-type
                              amnezia-vpn-shepherd-services)))
   (default-value (amnezia-vpn-configuration))
   (description
    "Run the Amnezia VPN client's privileged helper service
(@command{AmneziaVPN-service}) as a system (root) Shepherd service.  This
is the daemon that actually configures VPN tunnels, routes, and DNS; the
@code{amnezia-vpn} package's GUI client connects to it over a local
socket.  Install the @code{amnezia-vpn} package itself (e.g. in your
@code{operating-system}'s @code{packages} field, or per-user) to get the
GUI client on @code{PATH}.")))
