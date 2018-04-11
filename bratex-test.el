(ert-deftest test-bratex-delim= ()
  (let ((delim1 (make-bratex-delim :start 10
                                   :size "\\big" :amsflag "l" :bracket "\\{"))
        (delim2 (make-bratex-delim :start 10
                                   :size "\\big" :amsflag "l" :bracket "\\{"))
        (delim3 (make-bratex-delim :start 20
                                   :size "\\big" :amsflag "l" :bracket "\\}"))
        (delim4 (make-bratex-delim :start 10
                                   :size nil :amsflag nil :bracket "\\{"))
        (delim5 (make-bratex-delim :start 10
                                   :size nil :amsflag "" :bracket "\\{"))
        (delim6 (make-bratex-delim :start 10
                                   :size "" :amsflag nil :bracket "\\{"))
        (delim6 (make-bratex-delim :start 10
                                   :size "" :amsflag "" :bracket "\\{"))
        )
    (should (bratex-delim= delim1 delim1))
    (should (bratex-delim= delim1 delim2))
    (should (bratex-delim= delim4 delim5))
    (should (bratex-delim= delim4 delim6))
    (should (bratex-delim= delim5 delim6))
    (should-not (bratex-delim= delim1 delim3))
    ))

(ert-deftest test-bratex-delim-end ()
  (let ((delim (make-bratex-delim :start 10
                                  :size "\\big" :amsflag "l" :bracket "\\{")))
    (should (= (bratex-delim-end delim) 17))))

(ert-deftest test-bratex-delim-to-string ()
  (should (string= (bratex-delim-to-string (make-bratex-delim :start 10
                                                              :size "\\big"
                                                              :amsflag "l"
                                                              :bracket "\\{"))
                   "\\bigl\\{")))

(ert-deftest test-bratex-balanced-amsflags-p ()
  (should (bratex-balanced-amsflags-p "l" "r"))
  (should (bratex-balanced-amsflags-p "" ""))
  (should (bratex-balanced-amsflags-p "" nil))
  (should (bratex-balanced-amsflags-p nil ""))
  (should (bratex-balanced-amsflags-p nil nil))
  (should-not (bratex-balanced-amsflags-p "r" "l"))
  (should-not (bratex-balanced-amsflags-p "l" "l"))
  (should-not (bratex-balanced-amsflags-p "r" "r"))
  (should-not (bratex-balanced-amsflags-p "l" ""))
  (should-not (bratex-balanced-amsflags-p "l" nil))
  (should-not (bratex-balanced-amsflags-p "" "r"))
  (should-not (bratex-balanced-amsflags-p nil "r")))

(ert-deftest test-bratex-balanced-delims-p ()
  (should (bratex-balanced-delims-p
           (make-bratex-delim :start 0 :size "\\big" :amsflag "l" :bracket "(")
           (make-bratex-delim :start 10 :size "\\big" :amsflag "r" :bracket ")")))
  (should (bratex-balanced-delims-p
           (make-bratex-delim :start 0 :size nil :amsflag nil :bracket "\\{")
           (make-bratex-delim :start 3 :size nil :amsflag nil :bracket "\\}"))))

(ert-deftest test-bratex-left-delim-p ()
  (should (bratex-left-delim-p
           (make-bratex-delim :start 0 :size "\\big" :amsflag "l" :bracket "(")))
  (should (bratex-left-delim-p
           (make-bratex-delim :start 0 :size "\\big" :amsflag "" :bracket "(")))
  (should (bratex-left-delim-p
           (make-bratex-delim :start 0 :size "\\big" :amsflag nil :bracket "(")))
  (should-not (bratex-left-delim-p
               (make-bratex-delim :start 0 :size "\\big" :amsflag "r" :bracket ")")))
  (should-not (bratex-left-delim-p
               (make-bratex-delim :start 0 :size "\\big" :amsflag "" :bracket ")")))
  (should-not (bratex-left-delim-p
               (make-bratex-delim :start 0 :size "\\big" :amsflag nil :bracket ")"))))

(ert-deftest test-bratex-right-delim-p ()
  (should (bratex-right-delim-p
           (make-bratex-delim :start 0 :size "\\big" :amsflag "r" :bracket ")")))
  (should (bratex-right-delim-p
           (make-bratex-delim :start 0 :size "\\big" :amsflag "" :bracket ")")))
  (should (bratex-right-delim-p
           (make-bratex-delim :start 0 :size "\\big" :amsflag nil :bracket ")")))
  (should-not (bratex-right-delim-p
               (make-bratex-delim :start 0 :size "\\big" :amsflag "l" :bracket "(")))
  (should-not (bratex-right-delim-p
               (make-bratex-delim :start 0 :size "\\big" :amsflag "" :bracket "(")))
  (should-not (bratex-right-delim-p
               (make-bratex-delim :start 0 :size "\\big" :amsflag nil :bracket "("))))
