;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;;(setq user-full-name "John Doe"
;;      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
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

(defun open_scratchpad (name)
  "Create a new buffer which must be saved when Emacs exits."
  (interactive "BNew buffer name: ")
  (let ((buf (generate-new-buffer name)))
    (with-current-buffer buf
      (setq buffer-offer-save t))
    (switch-to-buffer buf)))

(setq! inhibit-splash-screen t)
(setq! confirm-kill-emacs nil)

(global-prettify-symbols-mode t)

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-outrun-electric)

(setq doom-font (font-spec :family "Fira Code" :size 11))

;; allow undoing changes while staying in insert mode and making many changes
(setq evil-want-fine-undo t)

;; try to make projectile always open when in project
;;(setq projectile-switch-project-action 'treemacs)
(after! treemacs (treemacs-follow-mode))

;;(add-hook! 'window-setup-hook 'treemacs 'append)

;;(add-hook! projectile-after-switch-project-hook 'treemacs)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; Use focus follows mouse inside emacs
(setq! focus-follows-mouse t)
(setq! mouse-autoselect-window t)

;; Use nix-community/nixd as nix lsp - should be on path on our systems
(setq! lsp-nix-server-path "nixd")

(use-package! alicorn-mode
  :interpreter "alicorn"
  :mode "\\.alc\\'")

(use-package! capnp-mode
  :mode "\\.capnp\\'")

(advice-add 'rustic-cargo-add :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-fmt :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-check :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-clippy :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-clippy-fix :around #'envrc-propagate-environment)
(advice-add 'rustic-cargo-doc :around #'envrc-propagate-environment)


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

;; reopen treemacs after doom/reload
(add-hook! 'doom-after-reload-hook #'treemacs)
;; open treemacs when opening project
(add-hook! 'projectile-after-switch-project-hook #'treemacs-find-file)
(use-package! magit-pretty-graph
  :after magit
  :init
  (setq magit-pg-command
        (concat "git --no-pager log"
                " --topo-order --decorate=full"
                " --pretty=format:\"%H%x00%P%x00%an%x00%ar%x00%s%x00%d\""
                " -n 2000")) ;; Increase the default 100 limit

  (map! :localleader
        :map (magit-mode-map)
        :desc "Magit pretty graph" "p" (cmd! (magit-pg-repo (magit-toplevel)))))

(map!
  :map 'global-map
  "<mouse-6>" #'(lambda () (interactive) (scroll-right 3))
  "<mouse-7>" #'(lambda () (interactive) (scroll-left 3))
  )

;; ignore some folders for lsp mode
;; TODO: can we ignore things in .gitignore?

(setq ignore-lsp-dirs '("[/\\\\]\\.circleci\\'"
                        "[/\\\\]\\.clj-kondo\\'"
                        "[/\\\\]\\.github\\'"
                        "[/\\\\]\\.cpcache\\'"
                        "[/\\\\]\\.lsp\\'"
                        "[/\\\\]\\.node_modules\\'"
                        "[/\\\\]\\.shadow-cljs\\'"
                        "[/\\\\]target\\'"
                        "[/\\\\]result\\'"
                        ))

(after! lsp-mode
  (setq lsp-file-watch-ignored-directories (append lsp-file-watch-ignored-directories
                                                   ignore-lsp-dirs)))

;; (setq! lsp-clients-emmy-lua-jar-path (f-join (getenv "HOME") "sync/dev/lua/emmylua-ls/EmmyLua-LS-all.jar"))

;; use emmylua-ls on path as emmylua language server - should be script which runs java -jar emmylua etc
(setq! lsp-clients-emmy-lua-command `("emmylua-ls"))
;; override test as it looks for lsp-clients-emmy-lua-jar-path even if we set lsp-clients-emmy-lua-command
(defun lsp-clients-emmy-lua-test-fixed () "dummy test which is always true" t)
(advice-add 'lsp-clients-emmy-lua-test :override #'lsp-clients-emmy-lua-test-fixed)

;; stop writing dead programs points out vi keybindings made more sense on a layout which had : without a modifier
(map! :n ";" 'evil-ex)
;; remap : to ; so don't lose evil-repeat-find-char
(map! :n ":" 'evil-repeat-find-char)

;; workaround for https://github.com/emacs-tree-sitter/elisp-tree-sitter/issues/242
;; but it doesn't seem to do anything, still get x86_64 binaries
;; (use-package tsc
;;   :init (setq tsc-dyn-get-from '(:compilation)))

;; i don't like smart parens
(remove-hook 'doom-first-buffer-hook #'smartparens-global-mode)

;; goto-address-mode makes links clickable
(global-goto-address-mode 1)

;; ;; accept completion from copilot and fallback to company
;; (use-package! copilot
;;   :hook (prog-mode . copilot-mode)
;;   :bind (:map copilot-completion-map
;;               ("<tab>" . 'copilot-accept-completion)
;;               ("TAB" . 'copilot-accept-completion)
;;               ("C-TAB" . 'copilot-accept-completion-by-word)
;;               ("C-<tab>" . 'copilot-accept-completion-by-word)))

;; disable doom emacs truncating pin shas in packages.el
(advice-add '+emacs-lisp-truncate-pin :override (lambda () ()) )
