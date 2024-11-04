(load "./linux.scm")
(use-modules (gnu) (gnu system nss)
	     (nongnu packages linux)
             (nongnu system linux-initrd)
             ((admmq srvcs) #:prefix admmq:)
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
                         (device (uuid "6742-87C9" 'fat))
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

  (packages (append (list emacs emacs-exwm emacs-desktop-environment)
                    %base-packages))

  (services admmq:%desktop-services)

  (name-service-switch %mdns-host-lookup-nss))
