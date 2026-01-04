;;; init.el --- minimal, fast, macOS-friendly config -*- lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; macOS window chrome + basic UI
;; -----------------------------------------------------------------------------

(when (eq system-type 'darwin)
  ;; Make the macOS titlebar blend into Emacs.
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  (add-to-list 'default-frame-alist '(ns-appearance . dark))
  ;; Remove title text + proxy icon (document icon).
  (setq-default frame-title-format nil)
  (when (boundp 'ns-use-proxy-icon)
    (setq ns-use-proxy-icon nil)))

(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(set-fringe-mode 0)

(defun display-startup-echo-area-message () (message ""))

(setq visible-bell nil)
(setq ring-bell-function #'ignore)
(setq inhibit-startup-screen t)
(setq inhibit-startup-buffer-menu t)

;; -----------------------------------------------------------------------------
;; Defaults (encoding, prompts, files, scrolling)
;; -----------------------------------------------------------------------------

(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)

(setq use-dialog-box nil)
(defalias 'yes-or-no-p #'y-or-n-p)

(savehist-mode 1)
(setq savehist-additional-variables '(register-alist))

(setq backup-inhibited t)
(setq auto-save-default nil)

(setq-default indicate-empty-lines t)
(setq cursor-in-non-selected-windows 'hollow)
(setq highlight-nonselected-windows t)
(setq bidi-display-reordering nil)

(setq make-pointer-invisible t)
(setq sentence-end-double-space nil)

;; Scrolling: keep motion stable, avoid recentering jumps
(setq scroll-margin 2)
(setq scroll-conservatively scroll-margin)
(setq scroll-step 1)
(setq mouse-wheel-scroll-amount '(6 ((shift) . 1)))
(setq mouse-wheel-progressive-speed nil)
(setq mouse-wheel-inhibit-click-time nil)
(setq scroll-preserve-screen-position t)
(setq scroll-error-top-bottom t)
(setq next-error-recenter '(4))
(setq fast-but-imprecise-scrolling nil)
(setq jit-lock-defer-time 0)

;; Clipboard integration
(setq select-enable-clipboard t)
(setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))
(setq mouse-yank-at-point t)

;; -----------------------------------------------------------------------------
;; Editing (undo, case, indentation, wrapping policy)
;; -----------------------------------------------------------------------------

;; Undo: keep steps fine-grained + larger limits
(fset 'undo-auto-amalgamate #'ignore)
(setq undo-limit 67108864)
(setq undo-strong-limit 100663296)
(setq undo-outer-limit 1006632960)

;; Case sensitivity
(setq-default case-fold-search nil)
(setq dabbrev-case-fold-search nil)
(setq-default search-upper-case nil)

;; Indentation defaults
(setq-default indent-tabs-mode nil)
(setq default-tab-width 4)
(setq tab-width 4)
(setq default-fill-column 80)
(setq fill-column 80)

;; Wrapping policy:
;; - code: truncated lines (no wrap)
;; - text/org: visual line wrapping
(setq-default truncate-lines t)
(add-hook 'text-mode-hook #'visual-line-mode)
(add-hook 'prog-mode-hook (lambda () (setq-local truncate-lines t)))

;; -----------------------------------------------------------------------------
;; Packages (package.el + use-package)
;; -----------------------------------------------------------------------------

(setq package-enable-at-startup nil)
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)
(setq use-package-always-defer t)

(use-package package-utils
  :commands (package-utils-upgrade-all-and-recompile))

;; -----------------------------------------------------------------------------
;; Theme + fonts
;; -----------------------------------------------------------------------------

(load-theme 'modus-vivendi t)

(set-face-attribute 'default nil :font "Iosevka" :height 180)
(set-face-attribute 'fixed-pitch nil :font "Iosevka" :height 160)
(set-face-attribute 'variable-pitch nil :font "Iosevka" :height 160 :weight 'regular)

(use-package default-font-presets
  :demand t
  :commands (default-font-presets-scale-increase
             default-font-presets-scale-decrease
             default-font-presets-scale-reset))

(use-package hl-prog-extra
  :commands (hl-prog-extra-mode)
  :init (add-hook 'prog-mode-hook #'hl-prog-extra-mode))

;; -----------------------------------------------------------------------------
;; Display options
;; -----------------------------------------------------------------------------

(global-display-fill-column-indicator-mode -1)
(global-display-line-numbers-mode 1)
(setq-default display-line-numbers-widen t)

(set-face-attribute 'line-number nil :background "#000000")
(set-face-attribute 'line-number-current-line nil :background "#000000")

(setq column-number-mode t)

(show-paren-mode 1)
(setq blink-matching-paren nil)
(setq show-paren-delay 0.2)
(setq show-paren-highlight-openparen t)
(setq show-paren-when-point-inside-paren t)

;; -----------------------------------------------------------------------------
;; Spell checking (prog comments + text)
;; -----------------------------------------------------------------------------

(add-hook
 'after-change-major-mode-hook
 (lambda ()
   (cond
    ((derived-mode-p 'prog-mode) (flyspell-prog-mode))
    ((derived-mode-p 'text-mode) (flyspell-mode)))))

;; -----------------------------------------------------------------------------
;; Mode-specific formatting
;; -----------------------------------------------------------------------------

(add-hook
 'org-mode-hook
 (lambda ()
   (setq-local fill-column 120)
   (setq-local tab-width 2)
   (setq-local indent-tabs-mode nil)
   (setq-local ffip-patterns '("*.org"))))

(add-hook
 'emacs-lisp-mode-hook
 (lambda ()
   (setq-local fill-column 120)
   (setq-local tab-width 2)
   (setq-local indent-tabs-mode nil)
   (setq-local ffip-patterns '("*.el"))
   ;; Treat '-' and '_' as word chars for symbol navigation/search
   (modify-syntax-entry ?- "w")
   (modify-syntax-entry ?_ "w")))

(add-hook
 'python-mode-hook
 (lambda ()
   (setq-local fill-column 80)
   (setq-local tab-width 4)
   (setq-local indent-tabs-mode nil)
   (setq-local ffip-patterns '("*.py"))))

(add-hook
 'sh-mode-hook
 (lambda ()
   (setq-local fill-column 120)
   (setq-local tab-width 4)
   (setq-local indent-tabs-mode nil)
   (setq-local ffip-patterns '("*.sh"))))

(add-hook
 'c-mode-hook
 (lambda ()
   (setq-local fill-column 120)
   (setq-local c-basic-offset 4)
   (setq-local tab-width 4)
   (setq-local indent-tabs-mode nil)
   (setq-local ffip-patterns
               '("*.c" "*.cc" "*.cpp" "*.cxx"
                 "*.h" "*.hh" "*.hpp" "*.hxx" "*.inl"))
   ;; Treat '_' as word char
   (modify-syntax-entry ?_ "w")))

;; -----------------------------------------------------------------------------
;; Completion/UI (ivy/counsel/swiper, company, which-key)
;; -----------------------------------------------------------------------------

(use-package which-key
  :demand t
  :config (which-key-mode 1))

(use-package ivy
  :demand t
  :config
  (ivy-mode 1)
  (setq ivy-height-alist `((t . ,(lambda (_caller) (/ (frame-height) 2)))))

  ;; Vim-ish minibuffer navigation (hold Ctrl)
  (define-key ivy-minibuffer-map (kbd "C-j") #'next-line)
  (define-key ivy-minibuffer-map (kbd "C-k") #'previous-line)
  (define-key ivy-minibuffer-map (kbd "C-h") #'minibuffer-keyboard-quit)
  (define-key ivy-minibuffer-map (kbd "C-l") #'ivy-done)
  (define-key ivy-minibuffer-map (kbd "C-M-j") #'ivy-next-line-and-call)
  (define-key ivy-minibuffer-map (kbd "C-M-k") #'ivy-previous-line-and-call)
  (define-key ivy-minibuffer-map (kbd "<C-return>") #'ivy-done))

(use-package swiper
  :commands (swiper)
  :config (setq swiper-goto-start-of-match t))

(use-package counsel
  :commands (counsel-git-grep counsel-switch-buffer))

(use-package find-file-in-project
  :commands (find-file-in-project))

(use-package company
  :commands (company-complete-common company-dabbrev)
  :config
  (global-company-mode 1)
  (setq company-tooltip-limit 40)
  (setq company-dabbrev-downcase nil)
  (setq company-dabbrev-ignore-case nil)

  ;; Completion UI navigation
  (define-key company-active-map (kbd "C-j") #'company-select-next-or-abort)
  (define-key company-active-map (kbd "C-k") #'company-select-previous-or-abort)
  (define-key company-active-map (kbd "C-l") #'company-complete-selection)
  (define-key company-active-map (kbd "C-h") #'company-abort)
  (define-key company-active-map (kbd "<C-return>") #'company-complete-selection)
  (define-key company-search-map (kbd "C-j") #'company-select-next)
  (define-key company-search-map (kbd "C-k") #'company-select-previous))

(use-package diff-hl
  :demand t
  :config (global-diff-hl-mode 1))

(use-package highlight-numbers
  :hook (prog-mode . highlight-numbers-mode))

;; -----------------------------------------------------------------------------
;; Evil (vim layer) + related packages
;; -----------------------------------------------------------------------------

(use-package undo-fu)

(use-package evil
  :demand t
  :init
  (setq evil-undo-system 'undo-fu)
  (setq evil-search-module 'evil-search)
  :config
  (evil-mode 1)
  (setq evil-ex-search-case 'sensitive))

(use-package evil-numbers)
(use-package evil-surround
  :demand t
  :config (global-evil-surround-mode 1))

;; -----------------------------------------------------------------------------
;; Keybindings
;; - frequent: Command (⌘)  => s-...
;; - less frequent: Space leader
;; -----------------------------------------------------------------------------

(when (eq system-type 'darwin)
  ;; Make ⌘ act as Super (s-...) inside Emacs.
  (cond
   ((boundp 'mac-command-modifier) (setq mac-command-modifier 'super))
   ((boundp 'ns-command-modifier)  (setq ns-command-modifier  'super)))
  ;; Optional: ⌥ as Meta (M-...)
  (cond
   ((boundp 'mac-option-modifier) (setq mac-option-modifier 'meta))
   ((boundp 'ns-option-modifier)  (setq ns-option-modifier  'meta))))

;; Zoom (browser-style)
(global-set-key (kbd "C-=") #'default-font-presets-scale-increase)
(global-set-key (kbd "C--") #'default-font-presets-scale-decrease)
(global-set-key (kbd "C-0") #'default-font-presets-scale-reset)
(global-set-key (kbd "<C-mouse-4>") #'default-font-presets-scale-increase)
(global-set-key (kbd "<C-mouse-5>") #'default-font-presets-scale-decrease)
(global-set-key (kbd "<C-wheel-up>") #'default-font-presets-scale-increase)
(global-set-key (kbd "<C-wheel-down>") #'default-font-presets-scale-decrease)

;; Split helpers that also focus the new window
(defun my/split-right-and-focus ()
  "Vertical split (left/right) and focus the new window."
  (interactive)
  (split-window-right)
  (windmove-right))

(defun my/split-below-and-focus ()
  "Horizontal split (top/bottom) and focus the new window."
  (interactive)
  (split-window-below)
  (windmove-down))

;; Your “hot” Cmd bindings
(global-set-key (kbd "s-n") #'my/split-right-and-focus)    ;; ⌘n vertical split
(global-set-key (kbd "s-b") #'my/split-below-and-focus)    ;; ⌘b horizontal split
(global-set-key (kbd "s-h") #'windmove-left)               ;; ⌘h move left window
(global-set-key (kbd "s-j") #'windmove-down)
(global-set-key (kbd "s-k") #'windmove-up)
(global-set-key (kbd "s-l") #'windmove-right)
(global-set-key (kbd "s-w") #'kill-current-buffer)         ;; ⌘w kill buffer
(global-set-key (kbd "s-q") #'save-buffers-kill-terminal)  ;; ⌘q quit Emacs

;; ⌘Space: buffer switcher (replace with #'ibuffer if you want a literal list buffer)
(global-set-key (kbd "s-SPC")
                (lambda ()
                  (interactive)
                  (if (fboundp 'counsel-switch-buffer)
                      (counsel-switch-buffer)
                    (switch-to-buffer))))

;; ⌘⇧H / ⌘⇧L: previous/next buffer
(global-set-key (kbd "s-H") #'previous-buffer)
(global-set-key (kbd "s-L") #'next-buffer)

;; Evil-state specific bindings (only after evil loads)
(with-eval-after-load 'evil
  ;; Mouse secondary selection in insert state
  (define-key evil-insert-state-map (kbd "<down-mouse-1>") #'mouse-drag-secondary)
  (define-key evil-insert-state-map (kbd "<drag-mouse-1>") #'mouse-drag-secondary)
  (define-key evil-insert-state-map (kbd "<mouse-1>") #'mouse-start-secondary)
  (define-key evil-insert-state-map (kbd "<mouse-2>")
    (lambda (click)
      (interactive "*p")
      (when (overlay-start mouse-secondary-overlay)
        (mouse-yank-secondary click)
        (delete-overlay mouse-secondary-overlay))))

  ;; Vim increment/decrement
  (define-key evil-normal-state-map (kbd "C-a") #'evil-numbers/inc-at-pt)
  (define-key evil-normal-state-map (kbd "C-x") #'evil-numbers/dec-at-pt)
  (define-key evil-visual-state-map (kbd "g C-a") #'evil-numbers/inc-at-pt-incremental)
  (define-key evil-visual-state-map (kbd "g C-x") #'evil-numbers/dec-at-pt-incremental)

  ;; Insert-state completion triggers
  (define-key evil-insert-state-map (kbd "C-n") #'company-dabbrev)
  (define-key evil-insert-state-map (kbd "C-SPC") #'company-complete-common)

  ;; Allow window keymap access from ivy minibuffer (optional)
  (when (boundp 'evil-window-map)
    (define-key ivy-minibuffer-map (kbd "C-w") evil-window-map)))

;; Space leader for less-frequent commands (deterministic leader implementation)
(use-package evil-leader
  :demand t
  :after evil
  :config
  (global-evil-leader-mode)
  (evil-leader/set-leader "<SPC>")
  (evil-leader/set-key
    "k" #'find-file-in-project
    "f" #'counsel-git-grep
    "s" #'swiper
    "b" #'counsel-switch-buffer
    "c" #'compile
    "r" #'recompile))

;; -----------------------------------------------------------------------------
;; Shell & PATH integration (Fish / Homebrew)
;; -----------------------------------------------------------------------------

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (setq exec-path-from-shell-shell-name "/opt/homebrew/bin/fish")
  (setq exec-path-from-shell-arguments '("-l"))
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-envs
   '("PATH" "MANPATH" "JAVA_HOME" "PNPM_HOME" "GOKU_EDN_CONFIG_FILE")))

(setq shell-file-name "/opt/homebrew/bin/fish")
(setq explicit-shell-file-name "/opt/homebrew/bin/fish")
(setq shell-command-switch "-c")

;; -----------------------------------------------------------------------------
;; Compilation (ansi colors, scroll-to-error, quit window)
;; -----------------------------------------------------------------------------

(require 'ansi-color)

(defun my/colorize-compilation-buffer ()
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region compilation-filter-start (point))))

(add-hook 'compilation-filter-hook #'my/colorize-compilation-buffer)
(setq compilation-scroll-output 'first-error)

(add-hook 'compilation-mode-hook
          (lambda ()
            (local-set-key (kbd "q") #'quit-window)))

;; -----------------------------------------------------------------------------
;; Custom file (keep Custom noise out of init.el)
;; -----------------------------------------------------------------------------

(setq custom-file (concat user-emacs-directory "custom.el"))
(load custom-file 'noerror)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; init.el ends here
