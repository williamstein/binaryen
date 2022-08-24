;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --dce -all -S -o - | filecheck %s

;; If either try body or catch body is reachable, the whole try construct is
;; reachable
(module
  ;; CHECK:      (tag $e (param))
  (tag $e)

  ;; CHECK:      (func $foo
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $foo)

  ;; CHECK:      (func $try_unreachable
  ;; CHECK-NEXT:  (try $try
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch_all
  ;; CHECK-NEXT:    (nop)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $foo)
  ;; CHECK-NEXT: )
  (func $try_unreachable
    (try
      (do
        (unreachable)
      )
      (catch_all)
    )
    (call $foo) ;; shouldn't be dce'd
  )

  ;; CHECK:      (func $catch_unreachable
  ;; CHECK-NEXT:  (try $try
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:    (nop)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch_all
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $foo)
  ;; CHECK-NEXT: )
  (func $catch_unreachable
    (try
      (do)
      (catch_all
        (unreachable)
      )
    )
    (call $foo) ;; shouldn't be dce'd
  )

  ;; CHECK:      (func $both_unreachable
  ;; CHECK-NEXT:  (try $try
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch_all
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $both_unreachable
    (try
      (do
        (unreachable)
      )
      (catch_all
        (unreachable)
      )
    )
    (call $foo) ;; should be dce'd
  )

  ;; CHECK:      (func $throw
  ;; CHECK-NEXT:  (block $label$0
  ;; CHECK-NEXT:   (block $label$1
  ;; CHECK-NEXT:    (throw $e)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $throw
    ;; All these wrapping expressions before 'throw' will be dce'd
    (drop
      (block $label$0 (result externref)
        (if
          (i32.clz
            (block $label$1 (result i32)
              (throw $e)
            )
          )
          (nop)
        )
        (ref.null extern)
      )
    )
  )

  ;; CHECK:      (func $rethrow
  ;; CHECK-NEXT:  (try $l0
  ;; CHECK-NEXT:   (do
  ;; CHECK-NEXT:    (nop)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (catch $e
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (i32.const 0)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (rethrow $l0)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $rethrow
    (try $l0
      (do)
      (catch $e
        (drop
          ;; This i32.add will be dce'd
          (i32.add
            (i32.const 0)
            (rethrow $l0)
          )
        )
      )
    )
  )
)
