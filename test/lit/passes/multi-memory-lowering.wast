;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --enable-multi-memories --multi-memory-lowering --enable-bulk-memory --enable-extended-const -S -o - | filecheck %s

(module
  (memory $memory1 1)
  (memory $memory2 2)
  (data (memory $memory1) (i32.const 0) "a")
  (data (memory $memory2) (i32.const 1) "123")
)

;; CHECK: (module
 ;; CHECK-NEXT:(type $none_=>_i32 (func (result i32)))
 ;; CHECK-NEXT:(type $i32_=>_i32 (func (param i32) (result i32)))
 ;; CHECK-NEXT:(global $memory2_page_offset (mut i32) (i32.const 1))
 ;; CHECK-NEXT:(memory $combined_memory 3 65536)
 ;; CHECK-NEXT:(data (i32.const 0) "a")
 ;; CHECK-NEXT:(data (i32.add
  ;; CHECK-NEXT:(global.get $memory2_page_offset)
  ;; CHECK-NEXT:(i32.const 1)
 ;; CHECK-NEXT:) "123")
 ;; CHECK-NEXT:(func $multi_memory_size (result i32)
  ;; CHECK-NEXT:(return
   ;; CHECK-NEXT:(global.get $memory2_page_offset)
  ;; CHECK-NEXT:)
 ;; CHECK-NEXT:)
 ;; CHECK-NEXT:(func $multi_memory_size_0 (result i32)
  ;; CHECK-NEXT:(return
   ;; CHECK-NEXT:(i32.sub
    ;; CHECK-NEXT:(memory.size)
    ;; CHECK-NEXT:(global.get $memory2_page_offset)
   ;; CHECK-NEXT:)
  ;; CHECK-NEXT:)
 ;; CHECK-NEXT:)
 ;; CHECK-NEXT:(func $adjust_memory_offsets (param $page_delta i32) (result i32)
  ;; CHECK-NEXT:(local $1 i32)
  ;; CHECK-NEXT:(local.set $1
   ;; CHECK-NEXT:(call $multi_memory_size)
  ;; CHECK-NEXT:)
  ;; CHECK-NEXT:(memory.copy
   ;; CHECK-NEXT:(i32.add
    ;; CHECK-NEXT:(global.get $memory2_page_offset)
    ;; CHECK-NEXT:(local.get $page_delta)
   ;; CHECK-NEXT:)
   ;; CHECK-NEXT:(global.get $memory2_page_offset)
   ;; CHECK-NEXT:(i32.sub
    ;; CHECK-NEXT:(memory.size)
    ;; CHECK-NEXT:(global.get $memory2_page_offset)
   ;; CHECK-NEXT:)
  ;; CHECK-NEXT:)
  ;; CHECK-NEXT:(global.set $memory2_page_offset
   ;; CHECK-NEXT:(i32.add
    ;; CHECK-NEXT:(global.get $memory2_page_offset)
    ;; CHECK-NEXT:(local.get $page_delta)
   ;; CHECK-NEXT:)
  ;; CHECK-NEXT:)
  ;; CHECK-NEXT:(local.get $1)
 ;; CHECK-NEXT:)
 ;; CHECK-NEXT:(func $adjust_memory_offsets_0 (param $page_delta i32) (result i32)
  ;; CHECK-NEXT:(local $1 i32)
  ;; CHECK-NEXT:(local.set $1
   ;; CHECK-NEXT:(call $multi_memory_size_0)
  ;; CHECK-NEXT:)
  ;; CHECK-NEXT:(local.get $1)
 ;; CHECK-NEXT:)
;; CHECK-NEXT:)
