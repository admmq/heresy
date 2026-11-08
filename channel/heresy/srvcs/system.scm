(define-module (heresy srvcs system)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module ((gnu services base) #:prefix gnu-srvcs:)
  #:use-module ((gnu services desktop) #:prefix gnu-srvcs:)
  #:use-module ((heresy vars) #:prefix heresy:)
  #:export (%desktop-services
            %base-services))

(define %nonguix-signing-key
  (plain-file "nonguix.pub" "
(public-key
 (ecc
  (curve Ed25519)
  (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))

(define (with-heresy-substitutes services)
  (modify-services services
    (gnu-srvcs:guix-service-type
     config => (gnu-srvcs:guix-configuration
                (inherit config)
                (substitute-urls heresy:%substitutes-urls)
                (authorized-keys
                 (cons %nonguix-signing-key
                       (gnu-srvcs:guix-configuration-authorized-keys
                        config)))))))

(define %desktop-services
  (with-heresy-substitutes gnu-srvcs:%desktop-services))

(define %base-services
  (with-heresy-substitutes gnu-srvcs:%base-services))
