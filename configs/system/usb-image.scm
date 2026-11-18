;; guix system image --image-type=iso9660 ./configs/system/usb-image.scm

(use-modules (gnu)
             (nongnu system install)
             ((heresy pkgs linux) #:prefix heresy:))

(use-service-modules networking)
(use-package-modules gnome)  ; network-manager (nmcli, nmtui)

(operating-system
  (inherit installation-os-nonfree)
  (kernel heresy:my-linux-package)

  (packages (cons network-manager
                  (operating-system-packages installation-os-nonfree)))

  ;; Replace ConnMan with NetworkManager; the two conflict (both provide
  ;; 'networking').  wpa-supplicant and D-Bus are already in the base image.
  ;; Note: the guided installer's network step relies on ConnMan, so use
  ;; nmtui/nmcli on a TTY to get online instead.
  (services
   (cons (service network-manager-service-type)
         (modify-services (operating-system-user-services installation-os-nonfree)
           (delete connman-service-type)))))
