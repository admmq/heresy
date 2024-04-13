(use-modules (gnu) (gnu system nss)
	     (nongnu packages linux)
             (nongnu system linux-initrd)
             ((admmk srvcs) #:prefix admmk:)
             ((admmk pkgs emacs) #:prefix admmk:)

             ;; for pinning the kernel
             (srfi srfi-1)
             (guix channels)
             (guix inferior))

(use-service-modules desktop ssh)
(use-package-modules bootloaders certs
		     emacs emacs-xyz
		     ratpoison suckless wm
                     xorg)

(operating-system
  (host-name "grimoire")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

  (kernel linux-lts)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets '("/boot/efi"))))

  (file-systems (append
                 (list (file-system
                         (device (file-system-label "my-root"))
                         (mount-point "/")
                         (type "ext4"))
                       (file-system
                         (device (uuid "A5DD-CF6E" 'fat))
                         (mount-point "/boot/efi")
                         (type "vfat")))
                 %base-file-systems))

  (users (cons (user-account
                (name "user")
                (comment "nothing matters")
                (group "users")
                (supplementary-groups '("wheel" "netdev"
                                        "audio" "video")))
               %base-user-accounts))

  (packages (append (list
                     emacs emacs-exwm emacs-desktop-environment
                     admmk:emacs-stuff
                     xterm
                     nss-certs)
                    %base-packages))

  (services (append (list (service openssh-service-type)
                          (service xfce-desktop-service-type))
                    admmk:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
