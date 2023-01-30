;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; tell ispell what dictionary to use
(setq ispell-dictionary "american")
;; enable mouse interaction in terminal
(setq xterm-mouse-mode t)
;; ;; kill lsp popup documentation
;; (setq lsp-signature-auto-activate nil)

;; make emacs run as a service
;;(server-start)

;; make an empty save-requesting buffer open on default
;; to better act as a better gedit/notepad replacement
(defun open_scratchpad (name)
  "Create a new buffer which must be saved when Emacs exits."
  (interactive "BNew buffer name: ")
  (let ((buf (generate-new-buffer name)))
    (with-current-buffer buf
      (setq buffer-offer-save t))
    (switch-to-buffer buf)))

(setq inhibit-splash-screen t)
(open_scratchpad '"*scratchpad*")

;; org-capture templates (for convenience)
;; journal, todo, lab enby

(after! org
  (setq org-capture-templates
        '(("t" "Tasks" entry (file+headline "~/org/gtd.org" "Tasks")
           "- [ ] %?\n")
          ("j" "Journal" entry (file+olp+datetree "~/org/journal.org")
           "* [%U] %?\n")
          ("l" " Notebook" entry (file+olp+datetree "~/org/labenby.org")
           "* [%<%H:%M>] - %?")
          )))

(use-package! org-krita
  :config
  (add-hook 'org-mode-hook 'org-krita-mode))

(use-package! org-web-tools)

;; org-download setup
(use-package! org-download
  :config
  (setq org-image-actual-width 500)
  (setq org-download-method 'directory))

(add-hook! 'dired-mode-hook 'org-download-enable)

(setq-default org-download-image-dir ".")
(setq org-startup-with-inline-images t)
(setq org-startup-with-latex-preview t)

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "bootstrap-prime")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; Here are some additional functions/macros that could help you configure Doom:
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
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Make sure TRAMP gets a clean prompt
(setq tramp-terminal-type "tramp")

;; Enable crdt for collaboration
(use-package! crdt
  ;; Load crdt on-demand
  :commands (crdt-connect crdt-share-buffer))

(use-package! amulet-mode
  :mode "\\.ml\\'"
  :interpreter "amc"
  :config
  (add-hook! '(amulet-mode-hook) #'lsp!)
  (sp-local-pair 'amulet-mode "'" nil :actions nil))

(use-package! rg
  :config
  (setq rg-group-result nil)
  :commands (rg))

;; Configure Magit to use magit-todos for task tracking
(after! magit
  (add-hook 'magit-mode-hook #'magit-todos-mode)
  (setq magit-todos-update 500))

(use-package! magit-delta
  :hook
  (magit-mode . magit-delta-mode)
  )

;; following example of https://robert.kra.hn/posts/2021-02-07_rust-with-emacs/
(use-package! dap-mode
  :config
  (require 'dap-lldb)
  (require 'dap-gdb-lldb)

  ;; set dap mode like this https://github.com/emacs-lsp/dap-mode/issues/295
  (setq inhibit-eol-conversion t)

  ;; debug templates
  (dap-register-debug-template
   "Rust::LLDB Configuration"
   (list :type "lldb"
         :request "launch"
         :name "LLDB::Run"
         :target nil
         :cwd nil))
  )

(use-package! rustic
  :config
  (setq lsp-rust-analyzer-display-parameter-hints t)
  (setq lsp-rust-analyzer-inlay-hints-mode t)
  (setq lsp-rust-analyzer-server-display-inlay-hints t)
  )

;; (setq +format-on-save-enabled-modes
;;       '(not nix-mode))

(setq! lsp-nix-server-path "nil")
(setq! focus-follows-mouse t)
(setq! mouse-autoselect-window t)

(use-package! org-roam-ui)
(use-package! org-roam
  :init
  (setq org-roam-v2-ack t)
  (setq org-roam-directory "~/org-roam"))

;; disable proc macros until the proc-macro server stops crashing
;; this may be a while since it will depend on nix packaging a new
;; version of rustc
;; ;; enable proc macros in lsp
;; (setq lsp-rust-analyzer-proc-macro-enable t)

;; (use-package! lsp-mode
;;   :after (envrc-mode)
;;   :config
;;   (setq lsp-prefer-flymake nil)
;;   )

(use-package! scopes-mode
  :interpreter "scopes"
  :mode "\\.sc\\'")

(use-package! capnp-mode
  :mode "\\.capnp\\'")

(advice-add 'rustic-cargo-add :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-fmt :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-check :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-clippy :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-clippy-fix :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-doc :around #'envrc-propagate-environment)

(setq! vterm-shell "/etc/profiles/per-user/bootstrap/bin/fish")

(use-package! anki-editor)

(use-package! evil-motion-trainer
  :config
  (setq! global-evil-motion-trainer-mode 1))
