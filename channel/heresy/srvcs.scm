(define-module (heresy srvcs)
  #:use-module (gnu services)
  #:use-module (guix gexp)
  #:use-module ((gnu services base) #:prefix gnu-srvcs:)
  #:use-module ((gnu services desktop) #:prefix gnu-srvcs:)
  #:use-module (heresy vars)
  #:export (%desktop-services
            %base-services))

(define %desktop-services
  (modify-services gnu-srvcs:%desktop-services
    (gnu-srvcs:guix-service-type
     config => (gnu-srvcs:guix-configuration
		(inherit config)
		(substitute-urls %substitutes-urls)))))
