(use-modules (gnu) (gnu system nss)
             (nongnu packages linux)
             (nongnu system linux-initrd)
             ((heresy vars) #:prefix heresy:)
             ((heresy srvcs system) #:prefix heresy:)
             ((heresy pkgs emacs) #:prefix heresy:)
             ((heresy pkgs linux) #:prefix heresy:)
             ((heresy pkgs waymacs) #:prefix heresy:)
             ((heresy srvcs amnezia-vpn-service) #:prefix heresy:))

(use-service-modules desktop xorg)
(use-package-modules linux bootloaders certs window-management
                     gnome emacs emacs-xyz)

(operating-system
  (host-name "grimoire")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

  (kernel heresy:my-linux-package)
  (initrd-modules (base-initrd-modules linux-libre))
  (initrd microcode-initrd)
  (firmware (list linux-firmware
                  sof-firmware))

  (bootloader heresy:%efi-grub-configuration)

  (mapped-devices
   (list (mapped-device
          (source (uuid "cef010a5-45ea-446a-9855-f3e4503c50d4"))
          (target "cryptroot")
          (type luks-device-mapping))))

  (file-systems (append
                 (list (file-system
                         (device (file-system-label "ROOT"))
                         (mount-point "/")
                         (type "ext4")
                         (dependencies mapped-devices))
                       (file-system
                         (device (file-system-label "BOOT"))
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %base-file-systems))

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
                     heresy:waymacs swaylock waybar
                     emacs emacs-exwm emacs-desktop-environment
                     emacs-magit emacs-pdf-tools
                     heresy:emacs-stuff)
                    %base-packages))

  (services (append (list (service bluetooth-service-type)
                          (service gnome-desktop-service-type)
                          (service screen-locker-service-type
                                   (screen-locker-configuration
                                    (name "swaylock")
                                    (program (file-append swaylock "/bin/swaylock"))
                                    (using-pam? #t)
                                    (using-setuid? #f)))
                          (service heresy:amnezia-vpn-service-type))
                    heresy:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
