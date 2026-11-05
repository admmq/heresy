(use-modules (gnu) (gnu system nss)
             (nongnu packages linux)
             (nongnu system linux-initrd)
             ((heresy srvcs system) #:prefix heresy:)
             ((heresy pkgs emacs) #:prefix heresy:)
             ((heresy pkgs linux) #:prefix heresy:)
             ((heresy srvcs amnezia-vpn-service) #:prefix heresy:))

(use-service-modules desktop ssh)
(use-package-modules bootloaders certs
                     emacs emacs-xyz)

(operating-system
  (host-name "grimoire")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

  (kernel heresy:my-linux-package)
  (initrd-modules (append (list "vmd")
                          %base-initrd-modules))
  (initrd microcode-initrd)
  (firmware (list linux-firmware
                  sof-firmware))

  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets '("/boot/efi"))))

  (file-systems (append
                 (list (file-system
                         (device (file-system-label "ROOT"))
                         (mount-point "/")
                         (type "ext4"))
                       (file-system
                         (device (file-system-label "BOOT"))
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %base-file-systems))

  ;; 8 GiB swap file on the root file system, which the initrd mounts before
  ;; swap is turned on.  Guix doesn't create the file; once, as root:
  ;;   dd if=/dev/zero of=/swapfile bs=1M count=8192
  ;;   chmod 600 /swapfile && mkswap /swapfile
  (swap-devices (list (swap-space
                       (target "/swapfile"))))

  (users (cons (user-account
                (name "user")
                (comment "λ")
                (group "users")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  (packages (append (list
                     emacs emacs-exwm emacs-desktop-environment
                     emacs-magit emacs-pdf-tools
                     heresy:emacs-stuff)
                    %base-packages))

  (services (append (list (service bluetooth-service-type)
                          (service openssh-service-type)
                          (service gnome-desktop-service-type)
                          (service heresy:amnezia-vpn-service-type))
                    heresy:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
