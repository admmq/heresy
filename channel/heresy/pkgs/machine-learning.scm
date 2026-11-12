(define-module (heresy pkgs machine-learning)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages opencl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages vulkan)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake))

;;; Newer releases of the packages of the same name in (gnu packages
;;; machine-learning), whose recipes these follow.  Upstream bumps ggml's
;;; version along with llama.cpp's, so update them together.

(define-public ggml
  (package
    (name "ggml")
    (version "0.29.0")                  ;the one bundled with llama-cpp
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/ggml-org/ggml")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0qkc7w8qgbqd4ri2pqakb8hv5gar47zrfsbxr84za98gswkwgw0b"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list #$(string-append "-DGGML_BUILD_COMMIT=" version)
              "-DBUILD_SHARED_LIBS=ON"
              "-DGGML_BACKEND_DL=ON"
              (string-append "-DGGML_BACKEND_DIR="
                             #$output "/lib/backends")
              "-DGGML_VULKAN=ON"
              "-DGGML_BUILD_TESTS=ON"
              "-DGGML_OPENCL=ON"
              ;; Defaults to ON upstream, and then ggml-opencl rejects every
              ;; device that is not a Qualcomm Adreno GPU.
              "-DGGML_OPENCL_USE_ADRENO_KERNELS=OFF"
              "-DGGML_NATIVE=OFF"       ;no '-march=native'
              ;; Without '-march=native' the CPU backend gets built for
              ;; baseline x86-64, without AVX, AVX2, FMA and so on.  Build a
              ;; variant per microarchitecture instead and let ggml load the
              ;; best one for the running CPU, as upstream's releases do.
              #$@(if (or (target-x86?) (target-aarch64?))
                     '("-DGGML_CPU_ALL_VARIANTS=ON")
                     '())
              ;; Extra CPU kernels that llama.cpp enables for the ggml it
              ;; bundles, but that a standalone ggml leaves out by default.
              "-DGGML_LLAMAFILE=ON")))
    (inputs
     (list glslang
           opencl-icd-loader
           shaderc
           spirv-headers
           spirv-tools
           vulkan-headers
           vulkan-loader))
    (native-inputs
     (list opencl-headers pkg-config python-minimal-wrapper))
    (home-page "https://github.com/ggml-org/ggml")
    (synopsis "Tensor library for machine learning")
    (description "@code{ggml} is a @acronym{ML, Machine Learning} library
written in C and C++ with a focus on transformer inference, similar to ML
libraries such as PyTorch and TensorFlow.")
    (license license:expat)))

(define-public llama-cpp
  ;; Each release corresponds to a "b<N>" nightly build (named in the
  ;; release's nightly-tag.txt).  The prebuilt web UI is attached to that
  ;; build, and N is the build number that '--version' reports.
  (let ((build "12110")
        (commit "cd959ba"))               ;what the release tag points to
    (package
      (name "llama-cpp")
      (version "0.9.0")
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/ggml-org/llama.cpp")
               (commit (string-append "v" version))))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0dh2bk0zsr6d0fshykn3fazwgmgx1h83q3zwmwabc0ckzajsvfp8"))))
      (build-system cmake-build-system)
      (arguments
       (list
        ;; Many tests download models, as do the fixtures other tests
        ;; depend on, so neither build nor run the test suite.
        #:tests? #f
        #:configure-flags
        #~(list "-DBUILD_SHARED_LIBS=ON"
                "-DLLAMA_USE_SYSTEM_GGML=ON"
                "-DLLAMA_BUILD_TESTS=OFF"
                "-DLLAMA_BUILD_IS_DEV=OFF" ;a release, not a snapshot
                ;; Normally taken from the Git history.
                #$(string-append "-DLLAMA_BUILD_NUMBER=" build)
                #$(string-append "-DLLAMA_BUILD_COMMIT=" commit))
        #:phases
        #~(modify-phases %standard-phases
            ;; The web UI is embedded in llama-server.  With prebuilt assets
            ;; in tools/ui/dist, CMake neither builds it with npm nor
            ;; downloads it.
            (add-after 'unpack 'unpack-ui
              (lambda _
                (mkdir-p "tools/ui/dist")
                (invoke "tar" "-xf"
                        #$(this-package-native-input
                           (string-append "llama-b" build "-ui.tar.gz"))
                        "-C" "tools/ui/dist" "--strip-components=1"))))))
      (native-inputs
       (list (origin
               (method url-fetch)
               (uri (string-append "https://github.com/ggml-org/llama.cpp"
                                   "/releases/download/b" build
                                   "/llama-b" build "-ui.tar.gz"))
               (sha256
                (base32
                 "1a0xgwshdyr0nik46q7z1x4xivdx5br8hzkjm5gjhgxvdsq4n9xn")))))
      (inputs
       (list ggml openssl))
      (home-page "https://github.com/ggml-org/llama.cpp")
      (synopsis "Large language model inference in C/C++")
      (description
       "This package provides @command{llama-cli}, @command{llama-server} and
other tools to run large language models in the GGUF format on CPUs and GPUs.
@command{llama-server} offers an OpenAI-compatible HTTP API and a web
interface.  No models are included, but the tools can download them from
Hugging Face.")
      (license license:expat))))
