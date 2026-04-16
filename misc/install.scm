;; took from https://gitlab.com/nonguix/nonguix/-/blob/master/nongnu/system/install.scm
;; guix system image --image-type=iso9660 ./install.scm

(define-module (nongnu system install)
  #:use-module (nonguix transformations)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages zile)
  #:use-module (gnu system)
  #:use-module (gnu system install)
  #:use-module (gnu system linux-initrd)
  #:export (installation-os-nonfree))

(define installation-os-nonfree
  ((compose (nonguix-transformation-guix #:guix-source? #t)
            ;; FIXME: ‘microcode-initrd’ results in unbootable live system.
            (nonguix-transformation-linux #:initrd base-initrd))
   (operating-system
     (inherit installation-os)
     (initrd-modules (append (list "hv_storvsc" "hv_vmbus" "hv_utils"
                                   "hid-hyperv" "hv_balloon" "hyperv_drm")
                             %base-initrd-modules))
     (packages
      (append
       (list curl
             git
             neovim
             zile)
       (operating-system-packages installation-os))))))

installation-os-nonfree
