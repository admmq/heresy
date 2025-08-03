(use-modules (gnu) (gnu system nss)
             ((heresy srvcs) #:prefix heresy:))
(use-service-modules ssh desktop)
(use-package-modules bootloaders)

(operating-system
  (initrd-modules (append (list "hv_storvsc" "hv_vmbus" "hv_utils")
                          %base-initrd-modules))
  (host-name "hyperv-vm")
  (timezone "Europe/Moscow")
  (locale "en_US.utf8")

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
                (comment "no comment")
                (group "users")
                (supplementary-groups '("wheel" "netdev")))                          
               %base-user-accounts))

  (packages %base-packages)

  (services (append (list (service openssh-service-type))
		    heresy:%desktop-services))

  (name-service-switch %mdns-host-lookup-nss))
