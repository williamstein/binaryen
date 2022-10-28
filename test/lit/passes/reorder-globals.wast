;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: foreach %s %t wasm-opt --reorder-globals-always -S -o - | filecheck %s
;; RUN: foreach %s %t wasm-opt --reorder-globals-always --roundtrip -S -o - | filecheck --check-prefix RTRIP %s

;; Also check roundtripping here, so verify we don't end up emitting invalid
;; binaries.

;; Global $b has more uses, so it should be sorted first.
(module
  ;; CHECK:      (global $b i32 (i32.const 20))

  ;; CHECK:      (global $a i32 (i32.const 10))
  ;; RTRIP:      (global $b i32 (i32.const 20))

  ;; RTRIP:      (global $a i32 (i32.const 10))
  (global $a i32 (i32.const 10))
  (global $b i32 (i32.const 20))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (drop
      (global.get $b)
    )
  )
)

;; As above, but now with global.sets. Again $b should be sorted first.
(module
  ;; CHECK:      (global $b (mut i32) (i32.const 20))

  ;; CHECK:      (global $a (mut i32) (i32.const 10))
  ;; RTRIP:      (global $b (mut i32) (i32.const 20))

  ;; RTRIP:      (global $a (mut i32) (i32.const 10))
  (global $a (mut i32) (i32.const 10))
  (global $b (mut i32) (i32.const 20))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (global.set $b
  ;; CHECK-NEXT:   (i32.const 30)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $b
  ;; CHECK-NEXT:   (i32.const 40)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $a)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (global.set $b
  ;; RTRIP-NEXT:   (i32.const 30)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (global.set $b
  ;; RTRIP-NEXT:   (i32.const 40)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $a)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (global.set $b
      (i32.const 30)
    )
    (global.set $b
      (i32.const 40)
    )
    (drop
      (global.get $a)
    )
  )
)

;; As above, but flipped so now $a has more, and should remain first.
(module
  ;; CHECK:      (global $a (mut i32) (i32.const 10))
  ;; RTRIP:      (global $a (mut i32) (i32.const 10))
  (global $a (mut i32) (i32.const 10))
  ;; CHECK:      (global $b (mut i32) (i32.const 20))
  ;; RTRIP:      (global $b (mut i32) (i32.const 20))
  (global $b (mut i32) (i32.const 20))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (global.set $a
  ;; CHECK-NEXT:   (i32.const 30)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $a
  ;; CHECK-NEXT:   (i32.const 40)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (global.set $a
  ;; RTRIP-NEXT:   (i32.const 30)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (global.set $a
  ;; RTRIP-NEXT:   (i32.const 40)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (global.set $a
      (i32.const 30)
    )
    (global.set $a
      (i32.const 40)
    )
    (drop
      (global.get $b)
    )
  )
)

;; $b has more uses, but it depends on $a and cannot be sorted before it.
(module
  ;; CHECK:      (global $a i32 (i32.const 10))
  ;; RTRIP:      (global $a i32 (i32.const 10))
  (global $a i32 (i32.const 10))
  ;; CHECK:      (global $b i32 (global.get $a))
  ;; RTRIP:      (global $b i32 (global.get $a))
  (global $b i32 (global.get $a))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (drop
      (global.get $b)
    )
  )
)

;; $c has more uses, but it depends on $b and $a and cannot be sorted before
;; them. Likewise $b cannot be before $a.
(module
  ;; CHECK:      (global $a i32 (i32.const 10))
  ;; RTRIP:      (global $a i32 (i32.const 10))
  (global $a i32 (i32.const 10))
  ;; CHECK:      (global $b i32 (global.get $a))
  ;; RTRIP:      (global $b i32 (global.get $a))
  (global $b i32 (global.get $a))
  ;; CHECK:      (global $c i32 (global.get $b))
  ;; RTRIP:      (global $c i32 (global.get $b))
  (global $c i32 (global.get $b))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (drop
      (global.get $b)
    )
    (drop
      (global.get $c)
    )
    (drop
      (global.get $c)
    )
  )
)

;; As above, but without dependencies, so now $c is first and then $b.
(module
  ;; CHECK:      (global $c i32 (i32.const 30))

  ;; CHECK:      (global $b i32 (i32.const 20))

  ;; CHECK:      (global $a i32 (i32.const 10))
  ;; RTRIP:      (global $c i32 (i32.const 30))

  ;; RTRIP:      (global $b i32 (i32.const 20))

  ;; RTRIP:      (global $a i32 (i32.const 10))
  (global $a i32 (i32.const 10))
  (global $b i32 (i32.const 20))
  (global $c i32 (i32.const 30))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (drop
      (global.get $b)
    )
    (drop
      (global.get $c)
    )
    (drop
      (global.get $c)
    )
  )
)

;; As above, but a mixed case: $b depends on $a but $c has no dependencies. $c
;; can be first.
(module
  ;; CHECK:      (global $c i32 (i32.const 30))

  ;; CHECK:      (global $a i32 (i32.const 10))
  ;; RTRIP:      (global $c i32 (i32.const 30))

  ;; RTRIP:      (global $a i32 (i32.const 10))
  (global $a i32 (i32.const 10))
  ;; CHECK:      (global $b i32 (global.get $a))
  ;; RTRIP:      (global $b i32 (global.get $a))
  (global $b i32 (global.get $a))
  (global $c i32 (i32.const 30))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (drop
      (global.get $b)
    )
    (drop
      (global.get $c)
    )
    (drop
      (global.get $c)
    )
  )
)

;; Another mixed case, now with $c depending on $b. $b can be before $a.
(module
  ;; CHECK:      (global $b i32 (i32.const 20))

  ;; CHECK:      (global $c i32 (global.get $b))

  ;; CHECK:      (global $a i32 (i32.const 10))
  ;; RTRIP:      (global $b i32 (i32.const 20))

  ;; RTRIP:      (global $c i32 (global.get $b))

  ;; RTRIP:      (global $a i32 (i32.const 10))
  (global $a i32 (i32.const 10))
  (global $b i32 (i32.const 20))
  (global $c i32 (global.get $b))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $c)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $c)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (drop
      (global.get $b)
    )
    (drop
      (global.get $c)
    )
    (drop
      (global.get $c)
    )
  )
)

;; $b has more uses, but $a is an import and must remain first.
(module
  ;; CHECK:      (import "a" "b" (global $a i32))
  ;; RTRIP:      (import "a" "b" (global $a i32))
  (import "a" "b" (global $a i32))
  ;; CHECK:      (global $b i32 (i32.const 10))
  ;; RTRIP:      (global $b i32 (i32.const 10))
  (global $b i32 (i32.const 10))

  ;; CHECK:      (func $uses
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; RTRIP:      (func $uses
  ;; RTRIP-NEXT:  (drop
  ;; RTRIP-NEXT:   (global.get $b)
  ;; RTRIP-NEXT:  )
  ;; RTRIP-NEXT: )
  (func $uses
    (drop
      (global.get $b)
    )
  )
)
