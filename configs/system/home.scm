(load "../misc/linux.scm")
(use-modules (gnu) (gnu system nss)
	     (nongnu packages linux)
             (nongnu system linux-initrd)
             ((heresy srvcs) #:prefix heresy:)
             ((heresy pkgs emacs) #:prefix heresy:)
             ((my-local-packages)  #:prefix local:))

(use-service-modules desktop ssh)
(use-package-modules bootloaders certs
		     emacs emacs-xyz)

(operating-system
  (host-name "home")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

  (kernel local:my-linux-package)
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

  (users (cons (user-account
                (name "user")
                (comment "something matters")
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
                          (service gnome-desktop-service-type))
                    heresy:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
