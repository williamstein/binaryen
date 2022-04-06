;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s -all --possible-types -S -o - | filecheck %s

(module
  ;; CHECK:      (type $struct (struct ))
  (type $struct (struct))

  ;; CHECK:      (func $no-non-null (result (ref any))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.null any)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $no-non-null (result (ref any))
    ;; Cast a null to non-null in order to get wasm to validate, but of course
    ;; this will trap at runtime. The possible-types pass will see that no
    ;; actual type can reach the function exit, and will add an unreachable
    ;; here. (Replacing the ref.as with an unreachable is not terribly useful in
    ;; this instance, but it checks that we properly infer things, and in other
    ;; cases replacing with an unreachable can be good.)
    (ref.as_non_null
      (ref.null any)
    )
  )

  ;; CHECK:      (func $nested (result i32)
  ;; CHECK-NEXT:  (ref.is_null
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (nop)
  ;; CHECK-NEXT:     (block
  ;; CHECK-NEXT:      (block
  ;; CHECK-NEXT:       (drop
  ;; CHECK-NEXT:        (ref.null any)
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:       (unreachable)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (unreachable)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $nested (result i32)
    ;; As above, but add other instructions on the outside, which can also be
    ;; replaced.
    (ref.is_null
      (loop (result (ref func))
        (nop)
        (ref.as_func
          (ref.as_non_null
            (ref.null any)
          )
        )
      )
    )
  )

  ;; CHECK:      (func $yes-non-null (result (ref any))
  ;; CHECK-NEXT:  (ref.as_non_null
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $yes-non-null (result (ref any))
    ;; Similar to the above but now there *is* an allocation, and so we have
    ;; nothing to optimize. (The ref.as is redundant, but we leave that for
    ;; other passes, and we keep it in this test to keep the testcase identical
    ;; to the above in all ways except for having a possible type.)
    (ref.as_non_null
      (struct.new $struct)
    )
  )

  ;; CHECK:      (func $breaks
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block (result (ref any))
  ;; CHECK-NEXT:    (br $block
  ;; CHECK-NEXT:     (struct.new_default $struct)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block0 (result anyref)
  ;; CHECK-NEXT:    (br $block0
  ;; CHECK-NEXT:     (block
  ;; CHECK-NEXT:      (drop
  ;; CHECK-NEXT:       (ref.null $struct)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:      (unreachable)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $breaks
    ;; Check that we notice values sent along breaks. We should optimize
    ;; nothing here.
    (drop
      (block $block (result (ref any))
        (br $block
          (struct.new $struct)
        )
      )
    )
    ;; But here we send a null so we can optimize.
    (drop
      (block $block (result (ref null any))
        (br $block
          (ref.as_non_null
            (ref.null $struct)
          )
        )
      )
    )
  )

  ;; CHECK:      (func $get-nothing (result (ref $struct))
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $get-nothing (result (ref $struct))
    ;; This function returns a non-nullable struct by type, but does not
    ;; actually return a value in practice, and our whole-program analysis
    ;; should pick that up in optimizing the callers.
    (unreachable)
  )

  ;; CHECK:      (func $get-nothing-calls
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.is_null
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $get-nothing-calls
    ;; This should be optimized out since the call does not actually return any
    ;; type in practice.
    (drop
      (call $get-nothing)
    )
    ;; Test for the result of such a call reaching another instruction. We do
    ;; not optimize the ref.is_null here, because it returns an i32, and we do
    ;; not operate on such things in this pass, just references.
    (drop
      (ref.is_null
        (call $get-nothing)
      )
    )
    ;; As above, but an instruction that does return a reference, which we can
    ;; optimize away.
    (drop
      (ref.as_non_null
        (call $get-nothing)
      )
    )
  )

  ;; CHECK:      (func $two-inputs (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (select (result (ref any))
  ;; CHECK-NEXT:    (struct.new_default $struct)
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (select (result (ref any))
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (struct.new_default $struct)
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (select (result (ref any))
  ;; CHECK-NEXT:    (struct.new_default $struct)
  ;; CHECK-NEXT:    (struct.new_default $struct)
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (block
  ;; CHECK-NEXT:     (unreachable)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $two-inputs (param $x i32)
    ;; As above, but now the outer instruction has two children, and some of
    ;; them may have a possible type - we check all 4 permutations. Only in the
    ;; case where both inputs are nothing can we optimize away the select, as
    ;; only then will the select never have anything.
    (drop
      (select (result (ref any))
        (struct.new $struct)
        (call $get-nothing)
        (local.get $x)
      )
    )
    (drop
      (select (result (ref any))
        (call $get-nothing)
        (struct.new $struct)
        (local.get $x)
      )
    )
    (drop
      (select (result (ref any))
        (struct.new $struct)
        (struct.new $struct)
        (local.get $x)
      )
    )
    (drop
      (select (result (ref any))
        (call $get-nothing)
        (call $get-nothing)
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $locals
  ;; CHECK-NEXT:  (local $x anyref)
  ;; CHECK-NEXT:  (local $y anyref)
  ;; CHECK-NEXT:  (local $z anyref)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $z
  ;; CHECK-NEXT:   (struct.new_default $struct)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $y)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $z)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $locals
    (local $x (ref null any))
    (local $y (ref null any))
    (local $z (ref null any))
    ;; Assign to x from a call that actually will not return anything.
    (local.set $x
      (call $get-nothing)
    )
    ;; Never assign to y.
    ;; Assign to z an actual value.
    (local.set $z
      (struct.new $struct)
    )
    ;; Get the 3 locals, to check that we optimize. We can remove x and y.
    (drop
      (local.get $x)
    )
    (drop
      (local.get $y)
    )
    (drop
      (local.get $z)
    )
  )
)
