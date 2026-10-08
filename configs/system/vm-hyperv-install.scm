;; guix system image --image-type=iso9660 ./vm-hyperv-install.scm

(use-modules (guix)
             (gnu packages curl)
             (gnu packages version-control)
             (gnu packages vim)
             (gnu packages zile)
             (gnu packages linux)
             (gnu packages package-management)
             (gnu services base)
             (gnu system install)
             (gnu system linux-initrd)
             (guix channels)
             ((heresy vars) #:prefix heresy:)
             )

(operating-system
  (inherit installation-os)
  (initrd-modules (append (list "hv_storvsc" "hv_vmbus" "hv_utils"
                                "hid-hyperv" "hv_balloon" "hyperv_drm")
                          (base-initrd-modules linux-libre)))
                          ;; %base-initrd-modules))
  (packages
   (append
    (list curl
          git
          neovim
          zile)
    (operating-system-packages installation-os)))

  (services
   (modify-services (operating-system-user-services installation-os)
     (guix-service-type
      config => (guix-configuration
                 (inherit config)
                 (channels heresy:%channels)
                 (guix (guix-for-channels heresy:%channels))))))

  )
