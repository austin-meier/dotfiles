;; Elpaca handles packages; suppress the built-in package.el at startup.
(setq package-enable-at-startup nil)

;; macOS native-compilation: libgccjit shells out to the gcc driver to link
;; each .eln, and that link fails ("error invoking gcc driver") unless
;; LIBRARY_PATH points at the Homebrew gcc runtime and the SDK's libSystem/crt.
;; GUI launches don't inherit the shell environment, so set it here, before
;; any native compilation can run. Paths use Homebrew's version-agnostic
;; `current` symlinks so a gcc bump doesn't break this.
(when (eq system-type 'darwin)
  (let* ((brew (or (and (file-directory-p "/opt/homebrew") "/opt/homebrew")
                   "/usr/local"))
         (sdk (string-trim
               (shell-command-to-string "xcrun --show-sdk-path 2>/dev/null")))
         ;; libgcc runtime (incl. libemutls_w.a, needed to link trampolines)
         ;; lives in a version-specific target subdir, e.g.
         ;; .../current/gcc/aarch64-apple-darwin25/15 — glob for it.
         (gcc-target (file-expand-wildcards
                      (expand-file-name "opt/gcc/lib/gcc/current/gcc/*/*" brew)))
         (dirs (seq-filter
                (lambda (d) (and (stringp d) (file-directory-p d)))
                (append
                 (list (expand-file-name "opt/gcc/lib/gcc/current" brew)
                       (expand-file-name "opt/libgccjit/lib/gcc/current" brew))
                 gcc-target
                 (list (and (not (string-empty-p sdk))
                            (expand-file-name "usr/lib" sdk)))))))
    (when dirs
      (setenv "LIBRARY_PATH"
              (mapconcat #'identity
                         (delete-dups
                          (append dirs
                                  (let ((cur (getenv "LIBRARY_PATH")))
                                    (and cur (split-string cur ":" t)))))
                         ":")))))

;; Apply frame settings before the first frame is drawn so there's no
;; visible flash of the wrong size / extra chrome on launch.
(push '(fullscreen . maximized)    default-frame-alist)
(push '(tool-bar-lines . 0)        default-frame-alist)
(push '(menu-bar-lines . 0)        default-frame-alist)
(push '(vertical-scroll-bars)      default-frame-alist)

;; Skip implicit frame resizes during init (font/mode changes can trigger
;; expensive resize work otherwise).
(setq frame-inhibit-implied-resize t)
