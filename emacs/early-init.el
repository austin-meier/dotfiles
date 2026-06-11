;; Elpaca handles packages; suppress the built-in package.el at startup.
(setq package-enable-at-startup nil)

;; Apply frame settings before the first frame is drawn so there's no
;; visible flash of the wrong size / extra chrome on launch.
(push '(fullscreen . maximized)    default-frame-alist)
(push '(tool-bar-lines . 0)        default-frame-alist)
(push '(menu-bar-lines . 0)        default-frame-alist)
(push '(vertical-scroll-bars)      default-frame-alist)

;; Skip implicit frame resizes during init (font/mode changes can trigger
;; expensive resize work otherwise).
(setq frame-inhibit-implied-resize t)
