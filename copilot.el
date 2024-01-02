;;; copilot.el --- Emacs Copilot

;; View original Copyright "Copyright 2023 Justine Alexandra Roberts Tunney" at  https://github.com/jart/emacs-copilot/blob/563fc388e722dd7ff53b5399588b8413877b0839/copilot.el.
;;
;; Modifications by
;; Author: Romeo Valentin
;; Email: contact@romeov.me
;; License: Apache 2.0
;; Version: 0.2
;; This version contains two modifications:
;;  1) Make it possible to mark an area and use that as the input.
;;  2) Stream it over ssh from a more powerful computer.

(require 's)
(require 'evil)

(defgroup copilot nil
  "LLM code completion"
  :prefix "copilot-"
  :group 'editing)

(defcustom copilot-bin
  ;; "/home/romeo/Downloads/wizardcoder-python-34b-v1.0.Q3_K_M.llamafile"
  "/home/romeo/wizardcoder-python-34b-v1.0.Q5_K_M.llamafile"
  "Path of llamafile executable"
  :type 'string
  :group 'copilot)

;;;###autoload
(defun copilot-complete ()
  (interactive)
  (let* ((spot (point))
         (inhibit-quit t)
         (curfile (buffer-file-name))
         (cache (concat "/tmp/" (s-replace "/" "_" (concat curfile ".cache"))))
         (hist (concat curfile ".prompt"))
         (lang (file-name-extension curfile))

         ;; save code in visual selection to variable `selected-code`
         (code (buffer-substring-no-properties (region-beginning) (region-end)))

         ;; extract previous and current line
         ;; and save in variable 'code'
         ;; (code (save-excursion
         ;;         (dotimes (i 2)
         ;;           (when (> (line-number-at-pos) 1)
         ;;             (previous-line)))
         ;;         (beginning-of-line)
         ;;         (buffer-substring-no-properties (point) spot)))

         (system "\
You are a code generator used for code completion inside of Emacs. \
You work for a PhD Student in Engineering -- generated code needs to be clear but correct.
Comments explaining the code are encouraged as long as they are not obvious.
Writing test code is forbidden. \n")
          (prompt (format
                   "[INST]%sGenerate %s code to complete:[/INST]\n```%s\n%s"
                   (if (file-exists-p cache) "" system) lang lang code)))

          ;; (write-region prompt nil hist 'append 'silent)
          (write-region prompt nil hist nil 'silent)
          (evil-exit-visual-state)

          (with-local-quit
            ;; (message "%S" (list
            (call-process "ssh" hist (list (current-buffer) "/tmp/llamafileerror.txt") t
                "instance-4.us-central1-a.hai-gcp-towards-model"
                "./wizardcoder-python-34b-v1.0.Q5_K_M.llamafile"
                "--prompt-cache" cache
                "--prompt-cache-all"
                "--silent-prompt"
                "-c" "2048"
                "--temp" "0"
                "-ngl" "35"  ;; there's only 47 layers I think so this basically means "everything"
                "-r" "\"\\`\\`\\`\""  ;; reverse prompt, i.e. stops when this token is generated.
                "-f" "/dev/stdin"))))

(provide 'copilot)
;;; copilot.el ends here
