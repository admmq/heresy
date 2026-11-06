(use-modules (gnu) (gnu system nss)
             (nongnu packages linux)
             (nongnu system linux-initrd)
             ((heresy vars) #:prefix heresy-vars:)
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

  (bootloader heresy-vars:efi-grub-configuration)
  ;; (bootloader (bootloader-configuration
  ;;              (bootloader grub-efi-bootloader)
  ;;              (targets '("/boot/efi"))
  ;;              (theme (grub-theme (image #f)))))

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
                          ;; The gdm package sets the login-screen logo to the
                          ;; Guix icon via a gschema override; reset it to
                          ;; upstream's empty default through dconf.
                          (simple-service 'gdm-no-logo dconf-service-type
                                          (list (dconf-profile
                                                 (name "gdm")
                                                 (content
                                                  (list "user-db:user"
                                                        "system-db:gdm"
                                                        #~(string-append
                                                           "file-db:" #$gdm
                                                           "/share/gdm/greeter-dconf-defaults")))
                                                 (keyfile
                                                  (dconf-keyfile
                                                   (name "00-no-logo")
                                                   (content
                                                    (list "[org/gnome/login-screen]"
                                                          "logo=''")))))))
                          (service heresy:amnezia-vpn-service-type))
                    heresy:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
