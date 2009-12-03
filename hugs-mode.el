;; hugs-mode.el. Major mode for editing Hugs.
;; Copyright (C) 1989, Free Software Foundation, Inc., Lars Bo Nielsen
;; and Lennart Augustsson
;; modified by Peter Thiemann, March 1994
;; modified for hugs and xemacs by Olaf Chitil, April 1995

;; This file is not officially part of GNU Emacs.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY.  No author or distributor
;; accepts responsibility to anyone for the consequences of using it
;; or for whether it serves any particular purpose or works at all,
;; unless he says so in writing.  Refer to the GNU Emacs General Public
;; License for full details.

;; Everyone is granted permission to copy, modify and redistribute
;; GNU Emacs, but only under the conditions described in the
;; GNU Emacs General Public License.   A copy of this license is
;; supposed to have been given to you along with GNU Emacs so you
;; can know your rights and responsibilities.  It should be in a
;; file named COPYING.  Among other things, the copyright notice
;; and this notice must be preserved on all copies.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;; ORIGINAL AUTHOR
;;         Lars Bo Nielsen
;;         Aalborg University
;;         Computer Science Dept.
;;         9000 Aalborg
;;         Denmark
;;
;;         lbn@iesd.dk
;;         or: ...!mcvax!diku!iesd!lbn
;;         or: mcvax!diku!iesd!lbn@uunet.uu.net
;;
;; MODIFIED FOR Haskell BY
;;	   Lennart Augustsson
;;	   indentation stuff by Peter Thiemann
;; MODIFIED FOR Hugs BY
;;         Olaf Chitil
;;         http://www-i2.informatik.RWTH-Aachen.de/~chitil
;; MODIFIED FOR GNU Emacs BY
;;         Martin Schwenke <martin@meltin.net>
;;         http://meltin.net/hacks/emacs/
;;
;;
;; Please let me know if you come up with any ideas, bugs, or fixes.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst hugs-mode-version-string
  "HUGS-MODE, Version 0.4")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; CONSTANTS CONTROLLING THE MODE.
;;;
;;; These are the constants you might want to change,
;;; eg. for using the mode with Gofer instead of Hugs.
;;; 

;; The command used to start up the hugs-program.
(defconst hugs-prog-name "hugs" "*Name of program to run as hugs.")

;; Switches for hugs command line.  Print dots instead of backspacing
;; and messing up the buffer.
(defconst hugs-switches '("+.") "*List of switches for hugs command line.")

;; The left delimmitter for `load file'
(defconst hugs-use-left-delim ":load "
  "*The left delimiter for the filename when using \"load\".")

;; The left delimmitter for `load project'
(defconst hugs-use-left-delim-project ":project "
  "*The left delimiter for the filename when using \"project\".")

;; The left delimmitter for `also file'
(defconst hugs-use-left-delim-also ":also "
  "*The left delimiter for the filename when using \"also\".")

;; The right delimmitter for `load file', `load project', and `also file'
(defconst hugs-use-right-delim "\n"
  "*The right delimiter for the filename when using \"load\".")

(defconst hugs-reload-string ":reload\n"
  "*Command for reloading changed scripts.")

(defconst hugs-edit-string ":edit\n"
  "*Command for poping up window for the current script.")

(defconst hugs-use-left-delim-find ":find "
  "*The left delimiter for the identifier when using \"find\".")

(defconst hugs-use-right-delim-find "\n"
  "*The right delimiter for the identifier when using \"find\".")
  

;; A regular expression matching the prompt pattern in the inferior
;; shell
(defconst hugs-shell-prompt-pattern "^\\(?\\|[^>]*>\\) *"
  "*The prompt pattern for the inferior shell running Hugs.")

;;
(defconst hugs-first-command ""
  "*A command send to the inferior shell after starting hugs.")

;; The name of the process running Hugs.
(defconst hugs-process-name "Hugs" "*The name of the Hugs-process")

;; The name of the process running Hugs (This will also be the name of
;; the buffer).
(defconst hugs-buffer-name (concat "*" hugs-process-name "*")
  "*The name of the Hugs-process")

;;;
;;; END OF CONSTANTS CONTROLLING THE MODE.
;;;
;;; If you change anything below, you are on your own.
;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defvar hugs-mode-syntax-table nil "The syntax table used in hugs-mode.")

(defvar hugs-mode-map nil "The mode map used in hugs-mode.")

(defvar hugs-mode-abbrev-table nil "The abbrev-table used in hugs-mode.")

(defun hugs-mode ()
  "Major mode for editing Haskell scripts and executing them in Hugs.
Tab indents for Haskell code.
Shift-Return executes a Return and a Tab.
Comments are delimited with --
Paragraphs are separated by blank lines only.
Delete converts tabs to spaces as it moves back.

Key bindings:
=============

\\[hugs-mode-version]\t  Get the version of hugs-mode.
\\[hugs-pop-to-shell]\t  Pop to the Hugs window.
\\[hugs-load-saved-buffer]\t  Save the buffer, and load it into Hugs.
\\[hugs-load-file]\t  Asks for file name, and loads this script into Hugs.
\\[hugs-also-saved-buffer]\t  Save the buffer, and add it to already loaded scripts.
\\[hugs-also-file]\t  Asks for file name, and adds this script to already loaded ones.
\\[hugs-project-file]\t  Asks for project file name and loads this project into Hugs.
\\[hugs-reload]\t  Repeats the last load command, loading only changed scripts.
\\[hugs-edit]\t  Pops up window for current script.
\\[hugs-find]\t  Prompts for an identifier and pops up window with its definition.
\\[hugs-evaluate-expression]\t  Prompts for an expression and evalute it.


Mode map
========
\\{hugs-mode-map}
Runs hugs-mode-hook if non nil."
  (interactive)
  (kill-all-local-variables)
  (if hugs-mode-map
      ()
    (setq hugs-mode-map (make-sparse-keymap))
    (define-key hugs-mode-map [(control c) (control v)] 'hugs-mode-version)
    (define-key hugs-mode-map [(control c) (control s)] 'hugs-pop-to-shell)
    (define-key hugs-mode-map [(control c) (control l)] 'hugs-load-saved-buffer)
    (define-key hugs-mode-map [(control c) (control o)] 'hugs-load-file)
    (define-key hugs-mode-map [(control c) (control a)] 'hugs-also-saved-buffer)
    (define-key hugs-mode-map [(control c) (control z)] 'hugs-also-file)
    (define-key hugs-mode-map [(control c) (control p)] 'hugs-project-file)
    (define-key hugs-mode-map [(control c) (control r)] 'hugs-reload)
    (define-key hugs-mode-map [(control c) (control e)] 'hugs-edit)
    (define-key hugs-mode-map [(control c) (control f)] 'hugs-find)
    (define-key hugs-mode-map [(control c) (control x)] 'hugs-evaluate-expression)
    (define-key hugs-mode-map [(control c) (control c)] 'hugs-interrupt)
    (define-key hugs-mode-map [(shift return)] 'hugs-newline-and-indent)
    (define-key hugs-mode-map "\177"     'backward-delete-char-untabify))
  (make-variable-buffer-local 'indent-line-function)
  (setq indent-line-function 'indent-relative)
  (use-local-map hugs-mode-map)

  (require 'easymenu)
  (easy-menu-define
   hugs-mode-menu
   hugs-mode-map
   "Menu keymap for Hugs mode."
   '("Hugs"
     ["Load Buffer" hugs-load-saved-buffer t]
     ["Reload Buffer" hugs-reload t]
     ["Add Buffer" hugs-also-saved-buffer t]
     ["--------------------" nil nil]
     ["Load project" hugs-project-file t]
     ["Load script" hugs-load-file t]
     ["Add script" hugs-also-file t]
     ["--------------------" nil nil]
     ["Evaluate Expression" hugs-evaluate-expression t]
     ["Interrupt Evaluation" hugs-interrupt t]
     ["Find Definition" hugs-find t]
     ["--------------------" nil nil]
     ["Hugs Mode Version" hugs-mode-version t]))

  (setq major-mode 'hugs-mode)
  (setq mode-name "Hugs")
  (define-abbrev-table 'hugs-mode-abbrev-table ())
  (setq local-abbrev-table hugs-mode-abbrev-table)
  (if hugs-mode-syntax-table
      ()
    (setq hugs-mode-syntax-table (make-syntax-table))
    (modify-syntax-entry ?{  "(}1"    hugs-mode-syntax-table)
    (modify-syntax-entry ?}  "){4"    hugs-mode-syntax-table)
    (modify-syntax-entry ?-  "_ 23" hugs-mode-syntax-table)
    (modify-syntax-entry ?\\ "\\"     hugs-mode-syntax-table)
    (modify-syntax-entry ?*  "_"      hugs-mode-syntax-table)
    (modify-syntax-entry ?_  "_"      hugs-mode-syntax-table)
    (modify-syntax-entry ?'  "_"      hugs-mode-syntax-table)
    (modify-syntax-entry ?:  "_"      hugs-mode-syntax-table)
    (modify-syntax-entry ?|  "."      hugs-mode-syntax-table)
    )
  (set-syntax-table hugs-mode-syntax-table)
  (make-local-variable 'require-final-newline) ; Always put a new-line
  (setq require-final-newline t)	; in the end of file
  (make-local-variable 'comment-start)
  (setq comment-start "-- ")
  (make-local-variable 'comment-end)
  (setq comment-end "")
  (make-local-variable 'comment-column)
  (setq comment-column 60)		; Start of comment in this column
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "{-+ *\\|--+ *") ; This matches a start of comment
  (make-local-variable 'comment-multi-line)
  (setq comment-multi-line nil)

  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(hugs-font-lock-keywords t t))
  ;;
  ;; Adding these will fool the matching of parens. I really don't
  ;; know why. It would be nice to have comments treated as
  ;; white-space
  ;; 
  ;; (make-local-variable 'parse-sexp-ignore-comments)
  ;; (setq parse-sexp-ignore-comments t)
  ;; 
  (run-hooks 'hugs-mode-hook))		; Run the hook

(defun hugs-mode-version ()
  (interactive)
  (message hugs-mode-version-string))

(defun hugs-newline-and-indent ()
  (interactive)
  (let ((thing ""))
    (save-excursion
      (beginning-of-line)
      (if (looking-at ">")
	  (setq thing ">")))
    (newline)
    (insert-string thing)
    (eval `(,indent-line-function))))  ;; better way?
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; INFERIOR SHELL
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar hugs-shell-map nil "The mode map for hugs-shell.")

(defun hugs-shell ()
  "Inferior shell invoking Hugs.
It is not possible to have more than one shell running Hugs.
Like the shell mode with the same additional command as hugs-mode.

For variables controlling the mode see \"hugs-mode.el\".

Runs hugs-shell-hook if not nil."
  (interactive)
  (if (not (process-status hugs-process-name))
      (save-excursion			; Process is not running
	(message "Starting Hugs...")	; start up a new process
	(require 'shell)
	(set-buffer (apply 'make-comint hugs-process-name
			   hugs-prog-name nil hugs-switches))
	(erase-buffer)			; Erase the buffer if a previous
	(if hugs-shell-map		; process died in there
	    ()
	  (setq hugs-shell-map (copy-keymap shell-mode-map))
    (define-key hugs-shell-map [(control c) (control v)] 'hugs-mode-version)
    (define-key hugs-shell-map [(control c) (control l)] 'hugs-load-file)
    (define-key hugs-shell-map [(control c) (control o)] 'hugs-load-file)
    (define-key hugs-shell-map [(control c) (control a)] 'hugs-also-file)
    (define-key hugs-shell-map [(control c) (control z)] 'hugs-also-file)
    (define-key hugs-shell-map [(control c) (control p)] 'hugs-project-file)
    (define-key hugs-shell-map [(control c) (control r)] 'hugs-reload)
    (define-key hugs-shell-map [(control c) (control e)] 'hugs-edit)
    (define-key hugs-shell-map [(control c) (control f)] 'hugs-find)
    (define-key hugs-shell-map [(control c) (control x)] 'hugs-evaluate-expression)
	  )
	(use-local-map hugs-shell-map)
	(make-local-variable 'shell-prompt-pattern)
	(setq shell-prompt-pattern hugs-shell-prompt-pattern)
	(setq major-mode 'hugs-shell)
	(setq mode-name "Hugs Shell")
	(setq mode-line-format 
	      "-----Emacs: %17b   %M   %[(%m: %s)%]----%3p--%-")
	(set-process-filter (get-process hugs-process-name) 'hugs-process-filter)
	(process-send-string hugs-process-name hugs-first-command)
	(insert hugs-first-command)	
	(message "Starting Hugs...done.")
	(run-hooks 'hugs-shell-hook))))

(defun hugs-process-filter (proc str)
  (let ((cur (current-buffer))
	(pop-up-windows t))
    (pop-to-buffer hugs-buffer-name)
    (goto-char (point-max))
    (if (string= str "\b\b\b  \b\b\b")
	(backward-delete-char 4)
      (insert str))
    (set-marker (process-mark proc) (point-max))
    (pop-to-buffer cur)))

;;--------------

(defun hugs-pop-to-shell ()
  (interactive)
  (hugs-shell)
  (pop-to-buffer hugs-buffer-name))

(defun hugs-load-file (fil)
  (interactive "FLoad script: ")
  (hugs-shell)
  (save-some-buffers)
  (process-send-string hugs-process-name
		       (concat hugs-use-left-delim (expand-file-name fil)
			       hugs-use-right-delim)))

(defun hugs-project-file (fil)
  (interactive "FLoad project: ")
  (hugs-shell)
  (save-some-buffers)
  (process-send-string hugs-process-name
	       (concat hugs-use-left-delim-project (expand-file-name fil)
		       hugs-use-right-delim)))

(defun hugs-also-file (fil)
  (interactive "FLoad also script: ")
  (hugs-shell)
  (save-some-buffers)
  (process-send-string hugs-process-name
	       (concat hugs-use-left-delim-also (expand-file-name fil)
		       hugs-use-right-delim)))

(defun hugs-load-saved-buffer ()
  "Save the buffer, and send a `use file' to the inferior shell
running Hugs."
  (interactive)
  (let (file)
    (if (setq file (buffer-file-name))	; Is the buffer associated
	(progn				; with file ?
	  (save-buffer)
	  (hugs-shell)
	  (process-send-string hugs-process-name
		       (concat hugs-use-left-delim
			       (expand-file-name file)
			       hugs-use-right-delim)))
      (error "Buffer not associated with file."))))

(defun hugs-also-saved-buffer ()
  "Save the buffer, and send a `use project' to the inferior shell
running Hugs."
  (interactive)
  (let (file)
    (if (setq file (buffer-file-name))	; Is the buffer associated
	(progn				; with file ?
	  (save-buffer)
	  (hugs-shell)
	  (process-send-string hugs-process-name
			       (concat hugs-use-left-delim-also
				       (expand-file-name file)
				       hugs-use-right-delim)))
      (error "Buffer not associated with file."))))

(defun hugs-reload ()
   (interactive)
   (let ((buf (current-buffer)))
     (save-some-buffers)
     (hugs-pop-to-shell)
     (process-send-string hugs-process-name hugs-reload-string)
     (pop-to-buffer buf)))

(defun hugs-evaluate-expression (h-expr)
  "Prompt for and evaluate an expression"
  (interactive "sExpression: ")
  (let ((str (concat h-expr "\n"))
	(buf (current-buffer)))
    (hugs-pop-to-shell)
    (insert str)
    (process-send-string hugs-process-name str)
    (pop-to-buffer buf)))

(defun hugs-edit ()
   (interactive)
   (let ((buf (current-buffer)))
     (save-some-buffers)
     (hugs-pop-to-shell)
     (process-send-string hugs-process-name hugs-edit-string)
     (pop-to-buffer buf)))

(defun hugs-find (id)
  "Prompt for an identifier"
  (interactive "sIdentifier: ")
  (let ((buf (current-buffer)))
    (hugs-pop-to-shell)
    (process-send-string hugs-process-name
			 (concat hugs-use-left-delim-find
				 id
				 hugs-use-right-delim-find))
    (pop-to-buffer buf)))

(defun hugs-interrupt ()
   (interactive)
   (let ((buf (current-buffer)))
     (hugs-pop-to-shell)
     (comint-interrupt-subjob)
     (pop-to-buffer buf)))

;; ------------------------
;; font-lock-mode patterns, based on specs. in an earlier version
;; of haskell-mode.el


(defconst hugs-font-lock-keywords nil
 "Conservative highlighting of a Hugs buffer
(using font-lock.)")

;;; Ripped off from:
;;; Haskell font-lock mode for emacs, Graeme E Moss 14/1/97
;;; Based on an editing mode by Simon Marlow 11/1/92

(let ((haskell-id "[a-z_][a-zA-Z0-9_']+")
      (symbol "[-!#$%&*+./<=>?@\\^|~]")
      (haskell-reserved-ids
       (concat "\\b\\("
	       (mapconcat 
		'identity
		'("as"  "case"    "class"     "data"
		  "default" "deriving"  "else"
		  "hiding"  "if" "import"   "in"
		  "instance" "let"
		  "module" "newtype"  "of" "qualified"
		  "then" "type" "where" "infix[rl]?")
		"\\|")
	       "\\)\\b"))
      (haskell-basic-types 
       (concat "\\b\\("
	       (mapconcat 'identity
			  '("Bool" ;"()"
			    "String" "Char" "Int"
			    "Integer" "Float" "Double" "Ratio"
			    "Assoc" "Rational" "Array" "Ordering"
			    "Either" "Maybe" "Void")
			  "\\|")
	       "\\)\\b"))
      (haskell-prelude-classes
       (concat "\\b\\("
	       (mapconcat 'identity
			  '("Eq" "Ord" "Text" "Num" "Real" "Fractional" 
			    "Integral"   "RealFrac" "Floating" "RealFloat"
			    "Complex" "Ix" "Enum" "Show" "Read" "Bounded"
			    "Eval" "Monad" "MonadZero" "MonadPlus"
			    "Functor"
			    ;; ghc-isms
			    "_CCallable" "_CReturnable")
			  "\\|")
	       "\\)\\b"))
      (haskell-reserved-ops 
       (concat "[^!#$%&*+./<=>?@\\|~:^-^-]\\("
	       (mapconcat 'identity
			  '("\\.\\."  "::" "\\\\"
			    "=" "=>" "@" "|" "~"
			    "->")
			  "\\|")
	       "\\)[^!#$%&*+./<=>?@\\|:~^-^-]"))
      (monad-ops
       (concat "[^!#$%&*+./<=>?@\\|:~^-^-]\\(" 
	       (mapconcat 
		'identity
		'(">>" ">>=" "<-")
		"\\|")
	       "\\)[^!#$%&*+./<=>?@\\|:~^-^-]"))
      (monad-ids
       (concat "\\b\\("
	       (mapconcat 
		'identity
		'("return" "do")
		"\\|")
	       "\\)\\b"))
      (glasgow-haskell-ids
       (concat "\\b\\("
	       (mapconcat 
		'identity
		'("thenPrimIO"
		  "seqPrimIO" "returnPrimIO" 
		  "_ccall_" "_casm_"
		  "thenST" "seqST" "returnST"
		  "thenStrictlyST" "seqStrictlyST" "returnStrictlyST"
		  "unsafeInterleavePrimIO" "unsafePerformIO")
		"\\|")
	       "\\)\\b"))
      (glasgow-haskell-types
       (concat "\\b\\(" 
	       (mapconcat 
		'identity
		'("IO"    "PrimIO"  "_?ST"
		  "_Word" "_Addr"   "_?MVar"
		  "_?IVar" "_RealWorld"
		  "_?MutableByteArray"
		  "_?ByteArray")
		"\\|")
	       "\\)\\b")))
  (setq hugs-font-lock-keywords
	(list
	 (list haskell-reserved-ops    1 'font-lock-keyword-face)
	 (list haskell-reserved-ids    1 'font-lock-keyword-face)
	 (list monad-ops               1 'font-lock-function-name-face)
	 (list monad-ids               1 'font-lock-function-name-face)
	 (list glasgow-haskell-ids     1 'font-lock-function-name-face)
	 (list glasgow-haskell-types   1 'font-lock-type-face)
	 '("\\s-\\(()\\)\\(\\s-\\|)\\|$\\)" 1 'font-lock-type-face)
	 (list haskell-basic-types     1 'font-lock-type-face)
	 (list haskell-prelude-classes 1 'font-lock-type-face)
	 '("--.*$" 0 font-lock-comment-face t)
	 )))
;;(let ((hugs-id "[a-z_][a-zA-Z0-9_'#]+")
;;      (hugs-reserved-ids
;;	   (concat "\\b\\(" 
;;                   (mapconcat 
;;		       'identity
;;		       '("case"    "class"     "data"
;;		         "default" "deriving"  "else"
;;		         "hiding"  "if" "import"   "in"
;;		         "instance" "interface" "let"
;;			 "module" "of"   "renaming"
;;		         "then"  "to" "type" "where" "infix[rl]?")
;;		        "\\|")
;;	           "\\)[ \t\n:,]"))
;;       (hugs-reserved-ops
;;	   (mapconcat 'identity
;;		      '("\\.\\." "::" "= " "\\" "|" 
;;			"<-" "->" "=>" "-" "@" "~")
;;		      "\\|")))

;;      (setq hugs-font-lock-keywords
;;       (list
;;         '("--.*$". font-lock-comment-face)
;;         ; defining `='
;;         (list "[ \t\n]\\(=\\)[ \t\n]"   0 'font-lock-keyword-face)
;;         ; type declarations:
;;	 '("^>?[ \t\n]*\\([^:\n]*\\)::" . font-lock-function-name-face)
;;         ; guard `|'
;;         (list "^>?[ \t\n]*\\(|\\)[ \t\n]"   0 'font-lock-keyword-face)
;;         (list hugs-reserved-ids   0 'font-lock-keyword-face)
;;       )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;; END OF Hugs-MODE
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'hugs-mode)
