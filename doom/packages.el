;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
;(package! some-package)

;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/radian-software/straight.el#the-recipe-format
;(package! another-package
;  :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
;(package! this-package
;  :recipe (:host github :repo "username/repo"
;           :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
;(package! builtin-package :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
;(package! builtin-package :recipe (:nonrecursive t))
;(package! builtin-package-2 :recipe (:repo "myfork/package"))

;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see radian-software/straight.el#279)
;(package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
;(package! builtin-package :pin "1a2b3c4d5e")


;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
;(unpin! pinned-package)
;; ...or multiple packages
;(unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
;(unpin! t)
(package! magit-pretty-graph
  :recipe (:host github
           :repo "georgek/magit-pretty-graph")
  :pin "26dc5535a20efe781b172bac73f14a5ebe13efa9")

;; Use CRDT for collaborative editing
;; FIXME: this was not reliable, out of order edits :ded:
;; (package! crdt)

;; Use rg.el to enable ripgrep-based searching
(package! rg)

;; (package! magit-delta)

(package! alicorn-mode
  :recipe (:host github
           :repo "LunNova/emacs-alicorn-mode"
           :files ("*")))

;;(package! alicorn-mode
;; :recipe (:local-repo "~/sync/dev/fundament/emacs-alicorn-mode"
;;           :files ("*")))

(package! capnp-mode
  :recipe (:host github
           :repo "capnproto/capnproto"
           :files ("highlighting/emacs/capnp-mode.el")))

;; (package! evil-tutor
;;   :recipe (:host github
;;            :repo "syl20bnr/evil-tutor"
;;            :files ("evil-tutor.el" "tutor.txt")))

;; (package! anki-editor
;;   :recipe (:host github
;;            :repo "louietan/anki-editor"
;;            :files ("anki-editor.el")))

;; (package! evil-motion-trainer
;;  :recipe (:host github
;;           :repo "martinbaillie/evil-motion-trainer"
;;           :files ("evil-motion-trainer.el")))

(package! sticky-shell
  :recipe (:host github
           :repo "andyjda/sticky-shell"
           :files ("sticky-shell.el")))

;; TODO: get local code completion server working and point copilot at it
;; (package! copilot
;;   :recipe (:host github :repo "zerolfx/copilot.el" :files ("*.el" "dist")))
