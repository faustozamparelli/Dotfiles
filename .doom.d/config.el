;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!
(setq ns-use-proxy-icon nil)
(setq frame-title-format nil)

(setq doom-font (font-spec :family "Hack Nerd Font Mono" :size 18 :weight 'medium :style 'normal))
(setq doom-big-font (font-spec :family "Hack Nerd Font Mono" :size 28 :weight 'medium :style 'normal))

;; Remap C-c to act as ESC in insert mode
(define-key evil-insert-state-map (kbd "C-c") 'evil-normal-state)
;; Remap C-c to act as ESC in visualmode
(define-key evil-visual-state-map (kbd "C-c") 'evil-exit-visual-state)
;; remove the highlight
(map! :n "C-c" #'evil-ex-nohighlight)

;; setting the default shell in vterm
(setq vterm-shell "/opt/homebrew/bin/fish") ; Replace with the path to your Fish shell

;; needed for org mode
(setq ispell-program-name "/opt/homebrew/bin/aspell")

;; change the headings in org mode
(use-package! org-superstar
  :hook (org-mode . org-superstar-mode)
  :config
  ;; Customize headline bullets
  (setq org-superstar-headline-bullets-list '("●" "○" "•" "◦" "‣")))

;; double space = save
(map! :leader
      :desc "Save file"
      "s" #'save-buffer)

;;open vterm
(map! :leader
      :desc "Open vterm"
      "T" #'vterm)
(map! :leader
      :desc "Open vterm here"
      "t" #'+vterm/here)

;; org roam
(use-package! org-roam
  :custom
  (org-roam-directory (file-truename "/Users/faustozamparelli/Documents/Notes")) ; Set your desired directory
  :config
  (org-roam-db-autosync-mode))


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'cyberpunk)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.




;; Set initial window size
;; Dynamically set the initial frame size and position to center the frame
;; (setq initial-frame-alist
;;       (let* ((screen-width (display-pixel-width))
;;              (screen-height (display-pixel-height))
;;              (frame-width 400) ;; Width in columns
;;              (frame-height (/ screen-height (frame-char-height))) ;; Full screen height
;;              (frame-pixel-width (* frame-width (frame-char-width)))
;;              (frame-left (/ (- screen-width frame-pixel-width) 2))) ;; Center horizontally
;;         `((width . ,frame-width)
;;           (height . ,frame-height)
;;           (top . 0)  ;; Start at the top of the screen
;;           (left . ,frame-left))))

;; Apply the same settings to new frames
;; (setq default-frame-alist initial-frame-alist)
