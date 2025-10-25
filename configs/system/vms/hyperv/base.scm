(use-modules (gnu) (gnu system nss)
             (gnu system privilege)
             ((heresy srvcs) #:prefix heresy:))
(use-service-modules ssh networking avahi dbus)
(use-package-modules bootloaders libusb nfs linux)

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
                 (comment "λ")
                 (group "users")
                 (supplementary-groups '("wheel" "netdev")))
               %base-user-accounts))

  (packages %base-packages)

  (services (append (list (service openssh-service-type)
                          ;; Add udev rules for MTP devices so that non-root users can access
                          ;; them.
                          (simple-service 'mtp udev-service-type (list libmtp))

                          ;; Allow desktop users to also mount NTFS and NFS file systems
                          ;; without root.
                          (simple-service 'mount-setuid-helpers privileged-program-service-type
                                          (map file-like->setuid-program
                                               (list (file-append nfs-utils "/sbin/mount.nfs")
                                                     (file-append ntfs-3g "/sbin/mount.ntfs-3g"))))

                          (service network-manager-service-type)
                          (service wpa-supplicant-service-type) ;needed by NetworkManager
                          (service modem-manager-service-type)
                          (service usb-modeswitch-service-type)

                          ;; The D-Bus clique.
                          (service avahi-service-type)
                          (service polkit-service-type)
                          (service dbus-root-service-type)
                          (service ntp-service-type))
		    heresy:%base-services))

  (name-service-switch %mdns-host-lookup-nss))
