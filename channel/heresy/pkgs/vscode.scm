(define-module (heresy pkgs vscode)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages kerberos)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages virtualization)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (nonguix licenses)
  #:use-module (ice-9 match)
  #:export (%vscode-fhs-packages
            make-vscode-fhs))

(define (input->gexp-input input)
  "Return INPUT, a package or a (PACKAGE OUTPUT) list as found in 'inputs'
fields, as something that can be spliced into a G-expression."
  (match input
    ((package output) (gexp-input package output))
    (package package)))

(define %vscode-libraries
  ;; Libraries that the prebuilt binaries of VS Code link against or 'dlopen'.
  (list alsa-lib
        at-spi2-core
        cairo
        cups-minimal
        curl                            ;Microsoft authentication broker
        dbus
        e2fsprogs                       ;libcom_err.so.2, for Kerberos
        eudev                           ;libudev
        expat
        fontconfig
        (list gcc "lib")
        glib
        gtk+
        libnotify                       ;notifications
        libsecret                       ;secret storage, Settings Sync
        libsoup                         ;Microsoft authentication broker
        libx11
        libxcb
        libxcomposite
        libxcursor                      ;cursor themes
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxkbfile                      ;native-keymap
        libxrandr
        mesa                            ;libgbm, libGL, libEGL
        mit-krb5                        ;Kerberos proxy authentication
        nspr
        nss
        openssl                         ;extension signature verification
        pango
        pciutils                        ;GPU detection
        pulseaudio
        (list util-linux "lib")         ;libuuid
        wayland                         ;SwiftShader on Wayland
        webkitgtk-for-gtk3))            ;Microsoft authentication broker

(define-public vscode
  (package
    (name "vscode")
    (version "1.140.0")
    (source
     (let ((arch (match (%current-system)
                   ("aarch64-linux" "arm64")
                   (_ "x64"))))
       (origin
         (method url-fetch)
         (uri (string-append "https://update.code.visualstudio.com/"
                             version "/linux-" arch "/stable"))
         (file-name (string-append name "-" version "-" arch ".tar.gz"))
         (sha256
          (base32
           (match arch
             ("arm64"
              "19kzawp7zg880r692nsnv538nrznj6m25zs3nc0s3hjbbijsf2cn")
             ("x64"
              "1p60dm1k1fmmyns6fya123fiqyimig5jzwrwmwr9bm8kwblk286k")))))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; The license forbids redistributing the binaries.
      #:substitutable? #f
      #:strip-binaries? #f
      #:install-plan #~'(("." "lib/vscode/"))
      #:modules '((guix build copy-build-system)
                  (guix build gremlin)
                  (guix build utils)
                  (guix elf)
                  (ice-9 binary-ports)
                  (ice-9 match)
                  (ice-9 regex)
                  (ice-9 textual-ports)
                  (srfi srfi-1)
                  (sxml simple))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'patch-elf-files
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Have the prebuilt binaries, including Node.js add-ons and
              ;; the programs bundled with extensions, use Guix's dynamic
              ;; linker and find their libraries, as well as those they
              ;; 'dlopen'.
              (let* ((ld.so (search-input-file inputs
                                               #$(glibc-dynamic-linker)))
                     (library-path
                      (cons* (dirname ld.so) ;for DT_NEEDED entries of ld.so
                             #$(file-append nss "/lib/nss")
                             (map (lambda (directory)
                                    (string-append directory "/lib"))
                                  (list #$@(map input->gexp-input
                                                %vscode-libraries))))))
                (define (interpreter? elf)
                  (any (lambda (segment)
                         (= PT_INTERP (elf-segment-type segment)))
                       (elf-segments elf)))

                (define (patch file)
                  (let* ((elf (parse-elf (call-with-input-file file
                                           get-bytevector-all
                                           #:binary #t)))
                         (info (elf-dynamic-info elf)))
                    ;; Leave statically-linked programs, such as ripgrep,
                    ;; alone.
                    (when info
                      (when (interpreter? elf)
                        (invoke "patchelf" "--set-interpreter" ld.so file))
                      (invoke "patchelf" "--set-rpath"
                              (string-join
                               (delete-duplicates
                                (append (elf-dynamic-info-rpath info)
                                        (elf-dynamic-info-runpath info)
                                        library-path))
                               ":")
                              file))))

                (for-each patch
                          (find-files (string-append #$output "/lib/vscode")
                                      (lambda (file stat)
                                        (and (eq? 'regular (stat:type stat))
                                             (elf-file? file))))))))
          (add-after 'patch-elf-files 'patch-launcher
            (lambda* (#:key inputs #:allow-other-keys)
              ;; Do not depend on the way the launcher is invoked to find VS
              ;; Code, nor on the commands available in PATH.
              (let ((vscode (string-append #$output "/lib/vscode")))
                (substitute* (string-append vscode "/bin/code")
                  (("^([[:blank:]]*)VSCODE_PATH=.*" _ indent)
                   (string-append indent "VSCODE_PATH=\"" vscode "\"\n"))
                  (("\\$\\(which ")
                   (string-append "$(" (search-input-file inputs "bin/which")
                                  " "))
                  (("(if|\\|) grep " _ prefix)
                   (string-append prefix " "
                                  (search-input-file inputs "bin/grep") " "))
                  (("\\| tr ")
                   (string-append "| " (search-input-file inputs "bin/tr")
                                  " "))
                  (("\\$\\(id ")
                   (string-append "$(" (search-input-file inputs "bin/id")
                                  " "))))))
          (add-after 'patch-launcher 'install-wrapper
            (lambda _
              ;; Provide what VS Code expects from an FHS distribution:
              ;; GSettings schemas, without which GTK file dialogs abort;
              ;; 'xdg-open' and 'gio', with which Electron opens links
              ;; (including those of sign-in flows) and moves files to the
              ;; trash; and, when /etc/fonts is missing as on Guix System, a
              ;; configuration for the copy of Fontconfig that comes with
              ;; Electron.  (FONTCONFIG_FILE would leave out the files that
              ;; fonts.conf includes, and thus font aliases.)  Only append to
              ;; search paths, since the integrated terminal inherits them.
              (let ((wrapper (string-append #$output "/bin/code")))
                (mkdir-p (dirname wrapper))
                (call-with-output-file wrapper
                  (lambda (port)
                    (format port "#!~a
export XDG_DATA_DIRS=\"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:~a\"
export PATH=\"${PATH:+$PATH:}~a\"
if test -z \"$FONTCONFIG_FILE$FONTCONFIG_PATH\" &&
   test ! -e /etc/fonts/fonts.conf
then
    export FONTCONFIG_PATH=~a
fi
exec ~a \"$@\"~%"
                            #$(file-append bash-minimal "/bin/sh")
                            (string-append #$gtk+ "/share:"
                                           #$gsettings-desktop-schemas
                                           "/share")
                            (string-append #$xdg-utils "/bin:"
                                           #$glib:bin "/bin")
                            #$(file-append fontconfig "/etc/fonts")
                            (string-append #$output "/lib/vscode/bin/code"))))
                (chmod wrapper #o555))))
          (add-after 'install-wrapper 'install-desktop-integration
            (lambda _
              ;; Install what Microsoft's own packages install, following
              ;; 'resources/linux' in VS Code's repository.
              (let* ((vscode (string-append #$output "/lib/vscode"))
                     (code (string-append #$output "/bin/code"))
                     (share (string-append #$output "/share"))
                     ;; Microsoft's packages name the desktop entry after
                     ;; 'linuxDesktopName', which VS Code then uses for its
                     ;; windows, but only if the entry is in
                     ;; /usr/share/applications.  Otherwise, as here, it uses
                     ;; the 'desktopName' of package.json, so follow suit.
                     (desktop-name
                      (match:substring
                       (string-match
                        "\"desktopName\": *\"([^\"]+)\\.desktop\""
                        (call-with-input-file
                            (string-append vscode
                                           "/resources/app/package.json")
                          get-string-all))
                       1))
                     (license
                      "Multiple, see https://code.visualstudio.com/license"))
                (define (write-file file proc)
                  (mkdir-p (dirname file))
                  (call-with-output-file file proc #:encoding "UTF-8"))

                (define (write-xml file sxml)
                  (write-file file
                              (lambda (port)
                                (sxml->xml
                                 `(*TOP* (*PI* xml "version='1.0'")
                                         "\n" ,sxml "\n")
                                 port))))

                (write-file (string-append share "/applications/"
                                           desktop-name ".desktop")
                  (lambda (port)
                    (format port "[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=~a %F
Icon=vscode
Type=Application
StartupNotify=false
StartupWMClass=~a
Categories=TextEditor;Development;IDE;
MimeType=application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Name[cs]=Nové prázdné okno
Name[de]=Neues leeres Fenster
Name[es]=Nueva ventana vacía
Name[fr]=Nouvelle fenêtre vide
Name[it]=Nuova finestra vuota
Name[ja]=新しい空のウィンドウ
Name[ko]=새 빈 창
Name[ru]=Новое пустое окно
Name[zh_CN]=新建空窗口
Name[zh_TW]=開新空視窗
Exec=~a --new-window %F
Icon=vscode~%"
                            code desktop-name code)))
                (write-file (string-append share "/applications/" desktop-name
                                           "-url-handler.desktop")
                  (lambda (port)
                    (format port "[Desktop Entry]
Name=Visual Studio Code - URL Handler
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=~a --open-url %U
Icon=vscode
Type=Application
NoDisplay=true
StartupNotify=true
Categories=Utility;TextEditor;Development;IDE;
MimeType=x-scheme-handler/vscode;
Keywords=vscode;~%"
                            code)))
                (write-xml (string-append share
                                          "/mime/packages/code-workspace.xml")
                           `(mime-info
                             (@ (xmlns "http://www.freedesktop.org/standards/shared-mime-info"))
                             (mime-type
                              (@ (type "application/x-code-workspace"))
                              (comment "Visual Studio Code Workspace")
                              (glob (@ (pattern "*.code-workspace"))))))
                (write-xml (string-append share "/metainfo/"
                                          desktop-name ".metainfo.xml")
                           `(component
                             (@ (type "desktop"))
                             (id ,(string-append desktop-name ".desktop"))
                             (metadata_license ,license)
                             (project_license ,license)
                             (name "Visual Studio Code")
                             (url (@ (type "homepage"))
                                  "https://code.visualstudio.com")
                             (summary
                              "Visual Studio Code. Code editing. Redefined.")
                             (description
                              (p "Visual Studio Code is a new choice of tool \
that combines the simplicity of a code editor with what developers need for \
the core edit-build-debug cycle. See \
https://code.visualstudio.com/docs/setup/linux for installation instructions \
and FAQ."))
                             (screenshots
                              (screenshot
                               (@ (type "default"))
                               (image "https://code.visualstudio.com/home/home-screenshot-linux-lg.png")
                               (caption "Editing TypeScript and searching \
for extensions")))))

                (for-each
                 (match-lambda
                   ((file . link)
                    (mkdir-p (dirname link))
                    (symlink (string-append vscode "/" file) link)))
                 `(("resources/app/resources/linux/code.png"
                    . ,(string-append share "/pixmaps/vscode.png"))
                   ("resources/app/resources/linux/code.png"
                    . ,(string-append share "/icons/hicolor/512x512"
                                      "/apps/vscode.png"))
                   ("resources/completions/bash/code"
                    . ,(string-append share
                                      "/bash-completion/completions/code"))
                   ("resources/completions/zsh/_code"
                    . ,(string-append share "/zsh/site-functions/_code")))))))
          (add-after 'validate-runpath 'make-library-path-transitive
            (lambda _
              ;; Node.js add-ons that come with extensions get loaded into
              ;; the Electron process, and usually lack a RUNPATH.  Unlike
              ;; its DT_RUNPATH, the DT_RPATH of the executable applies to
              ;; them too, which lets them find libstdc++ and friends, as on
              ;; an FHS distribution.  This happens after 'validate-runpath'
              ;; since the latter only looks at DT_RUNPATH.
              (let* ((electron (string-append #$output "/lib/vscode/code"))
                     (library-path (string-join (file-runpath electron) ":")))
                (invoke "patchelf" "--remove-rpath" electron)
                (invoke "patchelf" "--force-rpath" "--set-rpath" library-path
                        electron)
                (unless (equal? (elf-dynamic-info-rpath
                                 (file-dynamic-info electron))
                                (string-split library-path #\:))
                  (error "failed to set DT_RPATH" electron))))))))
    (native-inputs (list patchelf))
    (inputs
     (append (list bash-minimal
                   coreutils-minimal
                   (list glib "bin")
                   grep
                   gsettings-desktop-schemas
                   which
                   xdg-utils)
             %vscode-libraries))
    (supported-systems '("x86_64-linux" "aarch64-linux"))
    (home-page "https://code.visualstudio.com/")
    (synopsis "Code editor from Microsoft")
    (description
     "Visual Studio Code is a source code editor that comes with debugging,
Git integration, an integrated terminal, code completion and refactoring.  It
can be extended through the Visual Studio Marketplace.

This is Microsoft's binary release, with all of its features: the
Marketplace, Settings Sync, Remote Development, Remote Tunnels, GitHub Copilot
and so on.  On Guix System, use @code{vscode-fhs} for extensions that download
prebuilt programs, such as language servers and debuggers.")
    (license (undistributable "https://code.visualstudio.com/license"))))

(define (fhs-dynamic-linker)
  "Return the file name of the dynamic linker on FHS distributions."
  (match (%current-system)
    ("aarch64-linux" "/lib/ld-linux-aarch64.so.1")
    (_ "/lib64/ld-linux-x86-64.so.2")))

(define %vscode-fhs-packages
  ;; Programs and libraries found on most FHS distributions, which prebuilt
  ;; programs that extensions download may expect.
  (list bash
        coreutils
        diffutils
        findutils
        gawk
        grep
        gzip
        procps
        sed
        tar
        which
        xz
        glibc-for-fhs
        glibc-utf8-locales
        tzdata
        curl
        e2fsprogs                       ;libcom_err.so.2, for Kerberos
        expat
        (list gcc "lib")
        glib
        icu4c                           ;.NET programs
        libsecret
        libxcrypt
        mit-krb5
        ncurses/tinfo
        openssl
        (list util-linux "lib")
        zlib))

(define (fhs-environment packages)
  "Return a directory that unites PACKAGES, with an ld.so.cache for its
libraries in etc/ld.so.cache."
  (computed-file "vscode-fhs-environment"
    (with-imported-modules '((guix build union)
                             (guix build utils))
      #~(begin
          (use-modules (guix build union)
                       (guix build utils))
          (union-build #$output (list #$@(map input->gexp-input packages))
                       #:create-all-directories? #t)
          (call-with-output-file "ld.so.conf"
            (lambda (port)
              (format port "~a/lib~%" #$output)))
          (mkdir-p (string-append #$output "/etc"))
          (invoke #$(file-append glibc-for-fhs "/sbin/ldconfig")
                  "-X" "-f" "ld.so.conf"
                  "-C" (string-append #$output "/etc/ld.so.cache"))))))

(define (vscode-fhs-launcher vscode environment)
  "Return a program that runs the 'code' command of VSCODE with bubblewrap, in
a mount namespace where /bin, /lib, /lib64, /sbin, /usr and /etc/ld.so.cache
come from ENVIRONMENT, and everything else from the host."
  (program-file "code"
    #~(begin
        (use-modules (ice-9 ftw)
                     (ice-9 match)
                     (srfi srfi-1))

        (define code #$(file-append vscode "/bin/code"))
        (define arguments (cdr (command-line)))

        (define (entries directory)
          ;; Return the file names of the entries of DIRECTORY.
          (map (lambda (name)
                 (string-append (if (string=? directory "/") "" directory)
                                "/" name))
               (scandir directory
                        (lambda (name)
                          (not (member name '("." "..")))))))

        (define (symbolic-link? file)
          (eq? 'symlink (stat:type (lstat file))))

        (define (append-to-search-path variable directories)
          (match (getenv variable)
            ((or #f "") directories)
            (value (string-append value ":" directories))))

        ;; Nothing to do on hosts that have an FHS dynamic linker already, nor
        ;; inside the environment, as in the integrated terminal.
        (when (or (file-exists? #$(fhs-dynamic-linker))
                  (getenv "GUIX_VSCODE_FHS"))
          (apply execl code code arguments))

        (apply execl #$(file-append bubblewrap "/bin/bwrap") "bwrap"
               (append
                ;; Share the root directory, except for what the environment
                ;; replaces.
                (append-map (lambda (file)
                              (cond ((member file
                                             '("/bin" "/etc" "/lib" "/lib32"
                                               "/lib64" "/libx32" "/sbin"
                                               "/usr"))
                                     '())
                                    ((string=? file "/dev")
                                     '("--dev-bind" "/dev" "/dev"))
                                    ((symbolic-link? file)
                                     (list "--symlink" (readlink file) file))
                                    ((file-is-directory? file)
                                     (list "--bind" file file))
                                    (else '())))
                            (entries "/"))
                ;; Turn the entries of /etc into symbolic links to the host's
                ;; /etc, mounted on /.host-etc, so that files that the host
                ;; replaces later on, such as resolv.conf, stay current.
                '("--perms" "0755" "--dir" "/etc"
                  "--bind" "/etc" "/.host-etc")
                (append-map (lambda (file)
                              (cond ((member file '("/etc/ld.so.cache"
                                                    "/etc/ld.so.conf"
                                                    "/etc/ld.so.conf.d"))
                                     '())
                                    ((symbolic-link? file)
                                     (list "--symlink" (readlink file) file))
                                    (else
                                     (list "--symlink"
                                           (string-append "/.host-etc/"
                                                          (basename file))
                                           file))))
                            (entries "/etc"))
                (list "--ro-bind"
                      #$(file-append environment "/etc/ld.so.cache")
                      "/etc/ld.so.cache"
                      "--symlink" #$(file-append environment "/bin") "/bin"
                      "--symlink" #$(file-append environment "/sbin") "/sbin"
                      "--symlink" #$(file-append environment "/lib") "/lib"
                      "--symlink" #$(file-append environment "/lib") "/lib64"
                      "--perms" "0755" "--dir" "/usr"
                      "--symlink" #$(file-append environment "/bin")
                      "/usr/bin"
                      "--symlink" #$(file-append environment "/sbin")
                      "/usr/sbin"
                      "--symlink" #$(file-append environment "/lib")
                      "/usr/lib"
                      "--symlink" #$(file-append environment "/lib")
                      "/usr/lib64"
                      "--symlink" #$(file-append environment "/share")
                      "/usr/share"
                      "--setenv" "GUIX_VSCODE_FHS" "1"
                      ;; Let programs find the commands and locales of the
                      ;; environment, after those of the host.
                      "--setenv" "PATH"
                      (append-to-search-path "PATH" "/usr/bin:/usr/sbin")
                      "--setenv" "GUIX_LOCPATH"
                      (append-to-search-path
                       "GUIX_LOCPATH"
                       #$(file-append environment "/lib/locale"))
                      "--" code)
                arguments)))
    #:guile guile-3.0))

(define* (make-vscode-fhs #:key (vscode vscode)
                          (packages %vscode-fhs-packages))
  "Return a package that runs VSCODE in an environment resembling an FHS
distribution, made of PACKAGES, on hosts lacking one."
  (package
    (name "vscode-fhs")
    (version (package-version vscode))
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils)
                       (ice-9 regex))
          (let ((launcher (string-append #$output "/bin/code"))
                (share (string-append #$output "/share")))
            (mkdir-p (dirname launcher))
            (symlink #$(vscode-fhs-launcher vscode
                                            (fhs-environment packages))
                     launcher)

            ;; Desktop entries and the like, pointing at the launcher.
            (copy-recursively #$(file-append vscode "/share") share)
            (substitute* (find-files (string-append share "/applications"))
              (((regexp-quote #$(file-append vscode "/bin/code")))
               launcher))))))
    (inputs (list bubblewrap guile-3.0 vscode))
    (supported-systems (package-supported-systems vscode))
    (home-page (package-home-page vscode))
    (synopsis "Visual Studio Code in an FHS-like environment")
    (description
     "This package runs Visual Studio Code in a light environment that
resembles an FHS distribution, with @file{/lib64}, @file{/usr} and an
@file{/etc/ld.so.cache}, so that the prebuilt programs that extensions
download, such as language servers, debuggers and the server of
@command{code tunnel}, run as they would there.  The environment shares
everything else with the host, but setuid programs such as @command{sudo} do
not work inside it.  On hosts with an FHS dynamic linker, VS Code runs
directly.")
    (license (package-license vscode))))

(define-public vscode-fhs
  (make-vscode-fhs))
