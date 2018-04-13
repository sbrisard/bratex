;;; bratex.el --- Manipulation of brackets in LaTeX mode

;; Copyright (C) 2018 Sébastien Brisard

;; Author: Sébastien Brisard
;; Maintainer: Sébastien Brisard
;; Created: 11 Apr 2018
;; Keywords: tex, wp
;; Homepage:

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides a few function to manipulate delimiters in
;; LaTeX mode.  A delimiter is defined here as a bracket, namely
;;
;;     \"(\", \")\", \"[\", \"]\", \"\{\" or \"\}\"
;;
;; and a size modifier, namely
;;
;;     \big, \Big, \bigg, \Bigg, \bigl, \Bigl, \biggl, \Biggl, \bigr,
;;     \Bigr, \biggr, or \Biggr.
;;
;; The following functions allow to interactively cycle through the
;; brackets or the sizes of a the delimiter pair at point
;;
;;   - `bratex-cycle-size',
;;   - `bratex-cycle-size-reverse',
;;   - `bratex-cycle-bracket',
;;   - `bratex-cycle-bracket-reverse'.
;;

;;; Code:
(require 'cl)

(defun bratex--empty-string-p (str)
  "Return t if STR is nil or \"\"."
  (string= (or str "") ""))

(defun bratex--cycle (elt lst)
  "Return the item that follows ELT in LST.

If ELT is the last item of LST, then the first item of LST is returned.
If ELT does not belong to LST, returns nil."
  (let ((tail (member elt lst)))
    (when tail (or (cadr tail) (car lst)))))

(cl-defstruct bratex-delim
  "Structure that defines a LaTeX delimiter (size modifier+bracket).

    - START: position of the start of the delimiter text in the buffer
    - SIZE: size modifier as a string (see `bratex--sizes')
    - AMSFLAG: optional extra \"l\" or \"r\" to be appended at the end
               of SIZE (AMSMath)
    - BRACKET: is the bracket type as a string (see
               `bratex--left-brackets' and `bratex--right-brackets')."
  start size amsflag bracket)

(defconst bratex--brackets '(("(" . ")") ("[" . "]") ("\\{" . "\\}"))
  "List or pairs of balanced LaTeX brackets.")

(defconst bratex--left-brackets (mapcar #'car bratex--brackets)
  "List of left LaTeX brackets.")

(defconst bratex--left-brackets-reverse (reverse bratex--left-brackets)
  "List of left LaTeX brackets in reverse order.")

(defconst bratex--right-brackets (mapcar #'cdr bratex--brackets)
  "List of right LaTeX brackets.")

(defconst bratex--right-brackets-reverse (reverse bratex--right-brackets)
  "List of right LaTeX brackets in reverse order.")

(defconst bratex--bracket-regexp
  (regexp-opt (apply #'append (map 'list
                                   (lambda (pair) (list (car pair) (cdr pair)))
                                   bratex--brackets)))
  "Regular expression that defines a LaTeX bracket.

This variable is generated automatically from `bratex--brackets'.

Implementation note: each dotted pair must first be converted to a true
\(nil-terminated) list.")

(defconst bratex--sizes '("" "\\big" "\\Big" "\\bigg" "\\Bigg")
  "List of LaTeX delimiter sizes in ascending order.

The listed sizes do not include the optional AMS flag.")

(defconst bratex--sizes-reverse (reverse bratex--sizes)
  "List of LaTeX delimiter sizes in descending order.

The listed sizes do not include the optional AMS flag.")

(defconst bratex--size-regexp "\\(\\\\[bB]ig\\{1,2\\}\\)\\([lr]\\)?"
  "Regular expression that defines a LaTeX delimiter size.")

(defconst bratex--delim-regexp (concat "\\(" bratex--size-regexp "\\)?"
                                       "\\(" bratex--bracket-regexp "\\)")
  "Regular expression that defines a LaTeX delimiter.

The regexp defines two parenthesized groups:

    1: the full size modifier (including AMS flag),
  - 2: the size modifier itself (see `bratex--sizes'),
  - 3: the AMS flag,
    4: the bracket.

Implementation note: this group indices should not be hard-coded.  Use the
functions `bratex--match-size', `bratex--match-amsflag' and
`bratex--match-bracket' instead.")

(defconst bratex--delim-distance 8
  "The maximum distance to search for `bratex--delim-regexp'.

See `thing-at-point-looking-at' for the exact meaning of this distance, which
should be set to the maximum length of a string representing a LaTeX delimiter
\(probably \"\biggl\{\").")

(defun bratex--match-size (&optional string)
  "Return size matched by last search of `bratex--delim-regexp'.

The size is returned as a string without text properties.

STRING should be given if the last search was by ‘string-match’ on STRING.
If STRING is nil, the current buffer should be the same buffer
the search/match was performed in."
  (match-string-no-properties 2))

(defun bratex--match-amsflag (&optional string)
  "Return AMS flag matched by last search of `bratex--delim-regexp'.

The flag is returned as a string without text properties.

STRING should be given if the last search was by ‘string-match’ on STRING.
If STRING is nil, the current buffer should be the same buffer
the search/match was performed in."
  (match-string-no-properties 3))

(defun bratex--match-bracket (&optional string)
  "Return bracket matched by last search of `bratex--delim-regexp'.

The flag is returned as a string without text properties.

STRING should be given if the last search was by ‘string-match’ on STRING.
If STRING is nil, the current buffer should be the same buffer
the search/match was performed in."
  (match-string-no-properties 4))

(defun bratex-delim= (delim1 delim2)
  "Return t if DELIM1 and DELIM2 are equal, nil otherwise."
  (and (= (bratex-delim-start delim1)
          (bratex-delim-start delim2))
       (string= (or (bratex-delim-size delim1) "")
                (or (bratex-delim-size delim2) ""))
       (string= (or (bratex-delim-amsflag delim1) "")
                (or (bratex-delim-amsflag delim2) ""))
       (string= (bratex-delim-bracket delim1)
                (bratex-delim-bracket delim2))))

(defun bratex-delim-length (delim)
  "Return the length of the string that represents DELIM."
  (+ (length (bratex-delim-size delim))
     (length (bratex-delim-amsflag delim))
     (length (bratex-delim-bracket delim))))

(defun bratex-delim-end (delim)
  "Return the position in the buffer of the end of DELIM."
  (+ (bratex-delim-start delim) (bratex-delim-length delim)))

(defun bratex-delim-to-string (delim)
  "Return the LaTeX string for DELIM."
  (concat (bratex-delim-size delim)
          (bratex-delim-amsflag delim)
          (bratex-delim-bracket delim)))

(defun bratex-delim-set-amsflag (delim)
  "Set the AMS flag of DELIM to the appropriate value."
  (setf (bratex-delim-amsflag delim)
        (cond ((bratex--empty-string-p (bratex-delim-size delim)) "")
              ((bratex-left-delim-p delim) "l")
              (t "r")))
  delim)

(defun bratex-balanced-amsflags-p (left right)
  "Return t if LEFT and RIGHT are balanced AMS flags, nil otherwise.

  - \"l\" \"r\" => t
  - nil nil => t
  - nil \"\" => t
  - \"\" nil => t
  - \"\" \"\" => t"
  (or (and (string= left "l") (string= right "r"))
      (and (or (null left) (string= left ""))
           (or (null right) (string= right "")))))

(defun bratex-balanced-delims-p (left right)
  "Return t if LEFT and RIGHT are balanced parentheses, nil otherwise."
  (and (<= (bratex-delim-end left) (bratex-delim-start right))
       (string= (bratex-delim-size left) (bratex-delim-size right))
       (bratex-balanced-amsflags-p (bratex-delim-amsflag left)
                                   (bratex-delim-amsflag right))
       (string= (bratex-delim-bracket right)
                (cdr (assoc (bratex-delim-bracket left) bratex--brackets)))))

(defun bratex-left-delim-p (delim)
  "Return t if DELIM is an opening (left) delimiter, nil otherwise."
  (or (string= (bratex-delim-amsflag delim) "l")
      (assoc (bratex-delim-bracket delim) bratex--brackets)))

(defun bratex-right-delim-p (delim)
  "Return t if DELIM is a closing (right) delimiter, nil otherwise."
  (or (string= (bratex-delim-amsflag delim) "r")
      (rassoc (bratex-delim-bracket delim) bratex--brackets)))

(defun bratex--match-delim ()
  "Return delimiter matched by last search of `bratex--delim-regexp'.

The returned delimiter includes the size and the bracket.  Assumes
that the current `match-data' actually matches a bracket.  This
function alters the current `match-data' and moves the point."
  (make-bratex-delim :start (match-beginning 0)
                     :size (bratex--match-size)
                     :amsflag (bratex--match-amsflag)
                     :bracket (bratex--match-bracket)))

(defun bratex-delim-at-point ()
  "Return the delimiter at point.

The point is not moved.  The match data is saved."
  (save-match-data
    (let ((p (point)) (found nil))
      (goto-char (- (point) bratex--delim-distance))
      (while (and (not found)
                  (re-search-forward bratex--delim-regexp nil t)
                  (<= (match-beginning 0) p))
        (setq found (> (match-end 0) p)))
      (goto-char p)
      (when found (bratex--match-delim)))))

(defun bratex-next-delim ()
  "Return the first delimiter located under or after the point.

The point is moved after the found delimiter.  The match data is saved."
  (save-match-data
    (when (re-search-forward bratex--delim-regexp nil t)
      (let ((delim (bratex--match-delim)))
        (goto-char (bratex-delim-end delim))
        delim))))

(defun bratex-previous-delim ()
  "Return the first delimiter located under or before the point.

The point is moved to the beginning of the found delimiter.  The match data is
saved."
  (save-match-data
    (when (re-search-backward bratex--delim-regexp nil t)
      (let ((delim (bratex-delim-at-point)))
        (goto-char (bratex-delim-start delim))
        delim))))

(defun bratex-right-delim (left)
  "Return the right delimiter matching the LEFT delimiter.

This function returns nil if no matching delimiter is found.  The
point is moved."
  (goto-char (bratex-delim-start left))
  (let ((not-found t) (inner nil) (candidate nil) (right nil))
    (while (and not-found (setq candidate (bratex-next-delim)))
      (if (bratex-left-delim-p candidate)
          (setq inner (cons candidate inner))
        ;; else
        (if (bratex-balanced-delims-p (car inner) candidate)
            (progn
              (pop inner)
              (when (null inner)
                (setq not-found nil right candidate)))
          ;; else: break out of loop since we found unballanced delimiters
          (setq not-found nil))))
    right))

(defun bratex-left-delim (right)
  "Return the left delimiter that matchess the RIGHT delimiter.

This function returns nil if no matching delimiter is found.  The
point is moved."
  (goto-char (bratex-delim-end right))
  (let ((not-found t) (inner nil) (candidate nil) (left nil))
    (while (and not-found (setq candidate (bratex-previous-delim)))
      (if (bratex-right-delim-p candidate)
          (setq inner (cons candidate inner))
        ;; else
        (if (bratex-balanced-delims-p candidate (car inner))
            (progn
              (pop inner)
              (when (null inner) (setq not-found nil left candidate)))
          ;; else: break out of loop since we found unballanced delimiters
          (setq not-found nil))))
    left))

(defun bratex-balanced-delims ()
  "Return the balanced delimiters at point as a (left . right) list."
  (save-excursion
    (let ((this (bratex-delim-at-point)) (pair))
      (when this
        (cond ((and (bratex-left-delim-p this)
                    (setq that (bratex-right-delim this)))
               (list this that))
              ((and (bratex-right-delim-p this)
                    (setq that (bratex-left-delim this)))
               (list that this)))))))

(defun bratex-make-delim-cycle-size (delim &optional reverse)
  "Return a new delimiter that is a copy of DELIM, with increased size.
Optional argument REVERSE instructs the function to cycle the list of size modifiers in reverse order."
  (let ((size (or (bratex-delim-size delim) ""))
        (delim-new (copy-bratex-delim delim)))
    (setf (bratex-delim-size delim-new)
          (bratex--cycle size (if reverse bratex--sizes-reverse
                                bratex--sizes)))
    (when (or (bratex--empty-string-p size)
              (bratex--empty-string-p (bratex-delim-size delim-new)))
      (bratex-delim-set-amsflag delim-new))
    delim-new))

(defun bratex-make-smaller-delim (delim)
  "Return a new delimiter that is a copy of DELIM, with decreased size."
  (let ((size (bratex-delim-size delim))
        (delim-new (copy-bratex-delim delim)))
    (cond
     ;; "" → "\Bigg", handle AMS tags correctly
     ((or (null size) (string= size ""))
      (setf (bratex-delim-size delim-new) (car bratex--sizes-reverse)
            (bratex-delim-amsflag delim-new)
            (if (bratex-left-delim-p delim) "l" "r")))
     ;; "\big" → "", remove AMS tag
     ((string= (bratex-delim-size delim) (car bratex--sizes))
      (setf (bratex-delim-size delim-new) ""
            (bratex-delim-amsflag delim-new) ""))
     ;; Other cases, no need to alter AMS tag
     (t (setf (bratex-delim-size delim-new)
              (cadr (member size bratex--sizes-reverse)))))
    delim-new))

(defun bratex-make-delim-cycle-bracket (delim &optional reverse)
  "Return a new delimiter that is a copy of DELIM, with bracket cycled.

If REVERSE is non-nil, then the list of brackets is cycled in reverse order."
  (let ((delim-new (copy-bratex-delim delim))
        (brackets
         (if (bratex-left-delim-p delim)
             (if reverse bratex--left-brackets-reverse bratex--left-brackets)
           (if reverse bratex--right-brackets-reverse bratex--right-brackets))))
    (setf (bratex-delim-bracket delim-new)
          (bratex--cycle (bratex-delim-bracket delim) brackets))
    delim-new))

(defun bratex-transform-pair-at-point (transform)
  "Apply TRANSFORM to the pair of delimiters at point.

The function TRANSFORM takes a `bratex-delim' as input and returns a new
`bratex-delim'."
  (let ((p (point))
        (pair (bratex-balanced-delims)))
    (when pair
      (let* ((left (car pair))
             (right (cadr pair))
             (left-new (funcall transform left))
             (right-new (funcall transform right)))
        (setf (bratex-delim-start right-new)
              (+ (bratex-delim-start right)
                 (- (bratex-delim-length left-new)
                    (bratex-delim-length left))))
        (goto-char (bratex-delim-start right))
        (delete-region (point) (bratex-delim-end right))
        (insert (bratex-delim-to-string right-new))
        (goto-char (bratex-delim-start left))
        (delete-region (point) (bratex-delim-end left))
        (insert (bratex-delim-to-string left-new))
        ;; If we were in the right delimiter, move to beginning of
        ;; right delimiter.
        (if (>= p (bratex-delim-start right))
            ;; Point was in right delim. Move to beginning of new right delim.
            (goto-char (min (+ (bratex-delim-start right-new)
                               (- p (bratex-delim-start right)))
                            (- (bratex-delim-end right-new) 1)))
          ;; Else point was in left delim. Move to beginning of new left delim.
          (goto-char (min (+ (bratex-delim-start left-new)
                             (- p (bratex-delim-start left)))
                          (- (bratex-delim-end left-new) 1))))))))

(defun bratex-cycle-size ()
  "Cycle the size of the pair of delimiters at point in increasing order.

The typical sequence is (see `bratex--sizes'):

\\big(…\\big) → \\Big(…\\Big) → \\bigg(…\\bigg) → \\Bigg(…\\Bigg) → (…)

or (with AMS flags):

\(…) → \\bigl(…\\bigr) → \\Bigl(…\\Bigr) → \\biggl(…\\biggr) → \\Biggl(…\\Biggr)
 → (…)

When this function is called on a delimiter without size modifiers, AMS flags
are automatically added."
  (interactive)
  (bratex-transform-pair-at-point #'bratex-make-delim-cycle-size))

(defun bratex-cycle-size-reverse ()
  "Cycle the size of the pair of delimiters at point in decreasing order.

The typical sequence is (see `bratex--sizes-reverse'):

\\Bigg(…\\Bigg) → \\bigg(…\\bigg) → \\Big(…\\Big) → \\big(…\\big) → (…)

or (with AMS flags):

\\Biggl(…\\Biggr) → \\biggl(…\\biggr) → \\Bigl(…\\Bigr) → \\bigl(…\\bigr)
 → (…) → \\Biggl(…\\Biggr)

When this function is called on a delimiter without size modifiers, AMS flags
are automatically added."
  (interactive)
  (bratex-transform-pair-at-point
   (lambda (delim) (bratex-make-delim-cycle-size delim t))))

(defun bratex-cycle-bracket ()
  "Cycle the bracket type of the pair of delimiters at point.

The typical sequence is (see `bratex--brackets'):

\\bigl(…\\bigr) → \\bigl[…\\bigr] → \\bigl\{…\\bigr\}"
  (interactive)
  (bratex-transform-pair-at-point #'bratex-make-delim-cycle-bracket))

(defun bratex-cycle-bracket-reverse ()
  "Cycle the bracket type of the pair of delimiters at point (reverse order).

The typical sequence is (see `bratex--brackets'):

\\bigl\{…\\bigr\} → \\bigl[…\\bigr] → \\bigl(…\\bigr)"
  (interactive)
  (bratex-transform-pair-at-point
   (lambda (delim) (bratex-make-delim-cycle-bracket delim t))))

(defun bratex-config ()
  (local-set-key (kbd "<S-up>") #'bratex-cycle-size)
  (local-set-key (kbd "<S-down>") #'bratex-cycle-size-reverse)
  (local-set-key (kbd "<S-right>") #'bratex-cycle-bracket)
  (local-set-key (kbd "<S-left>") #'bratex-cycle-bracket-reverse))

(add-hook 'LaTeX-mode-hook #'bratex-config)

(provide 'bratex)

;;; bratex.el ends here
