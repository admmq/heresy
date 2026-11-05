(define-module (heresy pkgs amnezia)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system trivial)
  #:use-module (guix build-system qt)
  #:use-module (gnu packages)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages golang-web)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages vpn)
  #:use-module (heresy pkgs golang-amnezia))

(define-public amnezia-vpn-qtkeychain-source
  ;; Pinned by amnezia-client's client/3rd/qtkeychain submodule.  This
  ;; commit is an ancestor of upstream's later 0.15.0 release (15 commits
  ;; behind), not a tagged release itself.
  (let ((commit "7460df6a978669290de5b56c2d98b199b61c3f88")
        (revision "1"))
    (origin
      (method git-fetch)
      (uri (git-reference
            (url "https://github.com/frankosterfeld/qtkeychain.git")
            (commit commit)))
      (file-name (git-file-name "qtkeychain" (git-version "0.14.0" revision commit)))
      (sha256
       (base32 "1msybljij4ghrh76gyqz4cixg4qxnab1lkqc8q3f0bpsgpbrylj6")))))

(define-public amnezia-vpn-sortfilterproxymodel-source
  ;; Pinned by amnezia-client's client/3rd/SortFilterProxyModel
  ;; submodule: the mitchcurtis Qt6-compatible fork of
  ;; oKcerG/SortFilterProxyModel (not the atraczyk fork used by Jami).
  (let ((commit "f2881493e42bd7b7d5b7abe804dad084dd610b71")
        (revision "1"))
    (origin
      (method git-fetch)
      (uri (git-reference
            (url "https://github.com/mitchcurtis/SortFilterProxyModel.git")
            (commit commit)))
      (file-name (git-file-name "sortfilterproxymodel" (git-version "0.2" revision commit)))
      (sha256
       (base32 "0aq8msgksc668icsb5b3a5sszkz1i9n6gvf3j0rwlvb5y6k6s3ki")))))

(define %v2ray-rules-dat-version "202603162227")

(define v2ray-rules-dat-geoip
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/Loyalsoldier/v2ray-rules-dat"
                         "/releases/download/" %v2ray-rules-dat-version
                         "/geoip.dat"))
    (sha256
     (base32 "1la101sc9hnycf9vcqwrd5wif3xg86930vz7zqyg6ysxk1fr52z4"))))

(define v2ray-rules-dat-geosite
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/Loyalsoldier/v2ray-rules-dat"
                         "/releases/download/" %v2ray-rules-dat-version
                         "/geosite.dat"))
    (sha256
     (base32 "030ymjn6a7bi09wr26890vaa19gdnv3kyhnrznf0hgxyp0jkxy52"))))

(define-public v2ray-rules-dat
  (package
    (name "v2ray-rules-dat")
    (version %v2ray-rules-dat-version)
    (source v2ray-rules-dat-geoip)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let ((share (string-append #$output "/share/v2ray-rules-dat")))
            (mkdir-p share)
            (copy-file #$v2ray-rules-dat-geoip
                       (string-append share "/geoip.dat"))
            (copy-file #$v2ray-rules-dat-geosite
                       (string-append share "/geosite.dat"))))))
    (home-page "https://github.com/Loyalsoldier/v2ray-rules-dat")
    (synopsis "GeoIP and domain routing rule data for V2Ray/Xray")
    (description
     "This package provides the @file{geoip.dat} and @file{geosite.dat}
routing rule databases used by Xray-core (and V2Ray) to make per-country
and per-domain routing decisions.  They are distributed upstream as
compiled protobuf data derived from the @code{v2fly/geoip} and
@code{v2fly/domain-list-community} source lists; this package fetches the
upstream compiled release artifacts directly rather than rebuilding the
full V2Ray-core-based generation pipeline (which would pull in an entire
second, unrelated Xray/V2Ray fork purely to compile IP-range and
domain-list text files).  The Amnezia VPN client uses these to offer
geo-based split routing for its Xray/VLESS protocol backend.")
    (license license:gpl3+)))

(define %amnezia-vpn-gateway-environment
  ;; Premium and Free subscription keys only point at Amnezia's API
  ;; gateway; the client fetches the real config from it in requests
  ;; encrypted to the gateway's RSA key.  Upstream compiles that key and the
  ;; gateway proxy-list URLs in from CI secrets ($ENV{...} in
  ;; client/CMakeLists.txt), so without these every such key fails with
  ;; "Missing AGW public key" while self-hosted keys, which carry their
  ;; whole config, keep working.
  ;;
  ;; Values read out of the official 5.1.0.6 Linux release binary.  Keep the
  ;; key byte-identical: the client also hashes it into the AES key that
  ;; decrypts the downloaded proxy lists.  DEV_* is upstream's test
  ;; environment and stays unset.
  (list
   (list "PROD_AGW_PUBLIC_KEY"
         ;; Joined with a literal backslash-n: CMake pastes the value into
         ;; a C string literal through -D, which turns it into a newline.
         (string-join
          '("-----BEGIN PUBLIC KEY-----"
            "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAj5mxl/4DL3Sk89ntxs5G"
            "X3JawGQWIoq6rvNkOzNGuNgedNS2+pi6hZl3Izl1Io9om4KiUlMT6mgLO1hTr9q+"
            "s7CYhlvroFA7ErucF+9L+7FCt0Igi0kIK/R2/vxd/2HaUrorn/aSvvutkYwbfxqW"
            "SwtzE+RuBeDWGvEt937OW0oqYONPYv9E4T56Dz/EZ6v2t8ejAnKLbGD/GocMmipK"
            "7etFSiSMAB2RmaztqTq4NleBepfO80XpYlW9pCSXuHcE8wxHczkzxsbyMAMsG/K3"
            "vUQY6qPtohqqzSSBwa/8u2ptNHBeor7l7DdYXeR/Nqcc4z92VUkZ5lOVR4evkS5V"
            "/wQqp5tnOJEj3NjUhEhXFoNEapbZd1bh6iQoUk7jC1TdvKJ/nPKGZAsHRpr0rNKz"
            "fx/N/Oo6lr2yh/+ps6VxTkbPmB6E85WOO3UvjImZUY0XQdBjWle/4iJLdEC77Nr0"
            "jXhdgeypucy6jkB6iBHMeVMlrNMEV7UxoBR/cCNx55zu/8sml5ByiDvCDT7sRomN"
            "NgVt5S/FaVjYuzFUifJ12ToChXFgESKFmuso7WluEaWvMIGREdrMrKQKHfYLOzWF"
            "2B5ZJDqw4o03fU4J/6rw61M1b+rjVpXMjPnzc2A+RgcjTvXv955gfZkwe4lt5wk/"
            "3j8zMVo3+zLrMTAaEeIUM0UCAwEAAQ=="
            "-----END PUBLIC KEY-----")
          "\\n"))
   ;; Where the client looks up gateway proxies when the gateway itself is
   ;; unreachable.
   (list "PROD_S3_ENDPOINT"
         (string-join
          '("https://s3.eu-north-1.amazonaws.com/amnezia/"
            "https://storage.googleapis.com/lambda-list/"
            "https://amnzstrg01.blob.core.windows.net/lambda-list/"
            "https://objectstorage.eu-zurich-1.oraclecloud.com/n/zrhfyaq6qxvh/b/lambda-list/o/")
          ", "))
   (list "FALLBACK_S3_ENDPOINT"
         (string-join
          '("https://storage.mwsapis.ru/lambda-list/"
            "https://46.8.209.252/lambda-list/"
            "https://s3.cloudruserapi.net/lambda-list/")
          ", "))
   ;; Matched against the API endpoint of older keys issued through
   ;; Amnezia's Telegram bot; left empty, every such key is taken for
   ;; Premium V1.
   (list "FREE_V2_ENDPOINT" "13.248.139.44")
   (list "PREM_V1_ENDPOINT" "52.223.54.40")))

(define-public amnezia-vpn
  (let ((commit "94b51df24790bf52427afe82d81c87a95460bdfd")
        (revision "0"))
    (package
      (name "amnezia-vpn")
      (version (git-version "5.0.3.1" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/amnezia-vpn/amnezia-client")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "03g03qa272fv77142l9p47vvj9sdi01rz0gbb0dg6zn7my86m2wj"))
         (patches
          (search-patches
           "heresy/patches/amnezia-vpn-add-guix-cmake-find-modules.patch"))))
      (build-system qt-build-system)
      (arguments
       (list
        #:qtbase qtbase
        #:tests? #f                    ;no test suite built by default
        #:configure-flags
        #~(list "-DAMNEZIA_BUILD_TESTS=OFF")
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'unpack-vendored-submodules
              (lambda _
                (delete-file-recursively "client/3rd/qtkeychain")
                (copy-recursively #$amnezia-vpn-qtkeychain-source
                                  "client/3rd/qtkeychain")
                (delete-file-recursively "client/3rd/SortFilterProxyModel")
                (copy-recursively #$amnezia-vpn-sortfilterproxymodel-source
                                  "client/3rd/SortFilterProxyModel")))
            (add-after 'unpack-vendored-submodules 'remove-conan
              (lambda _
                (substitute* "CMakeLists.txt"
                  ((".*cmake/recipes_bootstrap\\.cmake.*") "")
                  ((".*cmake/conan_provider\\.cmake.*") "")
                  (("cmake_minimum_required\\(VERSION 3\\.25\\.0 FATAL_ERROR\\)")
                   (string-append
                    "cmake_minimum_required(VERSION 3.25.0 FATAL_ERROR)\n"
                    "list(PREPEND CMAKE_MODULE_PATH "
                    "\"${CMAKE_SOURCE_DIR}/client/cmake/Modules\")")))))
            (add-after 'remove-conan 'fix-runtime-dependency-bundling
              (lambda _
                (substitute* '("client/CMakeLists.txt"
                                "service/server/CMakeLists.txt")
                  (("(\\[\\[\\^/usr/lib\\.\\*\\]\\])" all)
                   (string-append all "\n        [[^/gnu/store/.*]]")))))
            (add-after 'fix-runtime-dependency-bundling 'fix-openvpn-rpath-chmod
              (lambda _
                (substitute* "service/server/CMakeLists.txt"
                  (("CONTENT \"file\\(RPATH_SET")
                   (string-append
                    "CONTENT \"file(CHMOD \\\""
                    "$<TARGET_FILE_DIR:${PROJECT}>/openvpn\\\" PERMISSIONS "
                    "OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ "
                    "GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)\\n"
                    "file(RPATH_SET")))))
            (add-after 'fix-openvpn-rpath-chmod 'disable-qt-deploy-scripts
              (lambda _
                (substitute* "client/CMakeLists.txt"
                  (("qt_generate_deploy_qml_app_script\\(")
                   "if(FALSE)\nqt_generate_deploy_qml_app_script(")
                  (("if \\(APPLE AND NOT IOS AND NOT MACOS_NE\\)")
                   (string-append
                    "endif() # GUIX: end skip qt-deploy-script\n"
                    "if (APPLE AND NOT IOS AND NOT MACOS_NE)")))
                (substitute* "service/server/CMakeLists.txt"
                  (("qt_generate_deploy_app_script\\(")
                   "if(FALSE)\nqt_generate_deploy_app_script("))
                (let ((port (open-file "service/server/CMakeLists.txt" "a")))
                  (display "\nendif() # GUIX: end skip qt-deploy-script\n" port)
                  (close-port port))))
            (add-after 'disable-qt-deploy-scripts 'fix-openvpn-install-rpath
              (lambda _
                (substitute* "service/server/CMakeLists.txt"
                  ((".*list\\(REMOVE_ITEM CONAN_EXECS_INSTALL.*") "")
                  (("# install openvpn via the service's dep set")
                   (string-append
                    "if(FALSE) # GUIX: openvpn's RUNPATH is already correct\n"
                    "# install openvpn via the service's dep set"))
                  (("# install drivers")
                   (string-append
                    "endif() # GUIX: end skip openvpn RUNPATH rewrite\n"
                    "# install drivers")))))
            (add-after 'qt-wrap 'unwrap-data-files
              (lambda* (#:key outputs #:allow-other-keys)
                (define bin (string-append (assoc-ref outputs "out") "/bin"))
                (define (unwrap name)
                  (define wrapped (string-append bin "/" name))
                  (define real (string-append bin "/." name "-real"))
                  (when (file-exists? real)
                    (delete-file wrapped)
                    (rename-file real wrapped)))
                (unwrap "geoip.dat")
                (unwrap "geosite.dat"))))))
      (native-inputs
       (list pkg-config
             qttools))
      (inputs
       (list amneziawg-go
             amnezia-xray-bindings
             libsecret
             libssh
             openssl
             openvpn
             qt5compat
             qtdeclarative
             qtremoteobjects
             qtsvg
             tun2socks
             v2ray-rules-dat))
      (home-page "https://amnezia.org/")
      (synopsis "Self-hosted VPN client with DPI-resistant protocols")
      (description
       "Amnezia VPN is a graphical client for deploying and connecting to
a self-hosted VPN server.  It supports OpenVPN, WireGuard, and AmneziaWG,
as well as protocols meant to resist deep packet inspection, such as
Shadowsocks, Cloak, and Xray/VLESS.  This package builds the desktop GUI
client (@command{AmneziaVPN}) together with its privileged helper service
(@command{AmneziaVPN-service}), which performs the actual network
configuration and speaks to the GUI over a local Qt Remote Objects
connection.")
      (license license:gpl3))))

(define-public amnezia-vpn-premium
  (package
    (inherit amnezia-vpn)
    (name "amnezia-vpn-premium")
    (arguments
     (substitute-keyword-arguments (package-arguments amnezia-vpn)
       ((#:configure-flags flags)
        ;; Once the gateway is usable, the client asks it for updates at
        ;; every start.  Guix takes care of updates.
        #~(cons "-DCLIENT_ENABLE_APP_UPDATES=0" #$flags))
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-before 'configure 'set-gateway-environment
              (lambda _
                (for-each (lambda (variable)
                            (apply setenv variable))
                          '#$%amnezia-vpn-gateway-environment)))))))
    (synopsis "Amnezia VPN client with support for Amnezia Premium")
    (description
     "This variant of @code{amnezia-vpn} can also use keys for Amnezia's own
Premium and Free services.  Those keys only point at Amnezia's API gateway,
so the client is built with the gateway's public key and endpoints, which
upstream leaves out of its source code.  Its built-in update check is
turned off; otherwise it is the same as @code{amnezia-vpn}.")))
