; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -loop-unswitch -loop-reduce -loop-simplifycfg -verify-memoryssa -S %s | FileCheck %s

; TODO: also run with NPM, but currently LSR does not preserve LCSSA, causing a verification failure on the test.
;   opt -passes='loop-mssa(simple-loop-unswitch<nontrivial>,loop-reduce,simplifycfg)' -verify-memoryssa -S %s | FileCheck %s

; Test case for PR47557.

; REQUIRES: x86-registered-target

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@a = external global i32, align 4
@c = external global [1 x i32], align 4

define i32* @test() {
; CHECK-LABEL: @test(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    switch i32 0, label [[ENTRY_SPLIT:%.*]] [
; CHECK-NEXT:    i32 1, label [[FOR_BODY3SPLIT:%.*]]
; CHECK-NEXT:    i32 2, label [[FOR_COND2_2_FOR_BODY3_CRIT_EDGE:%.*]]
; CHECK-NEXT:    ]
; CHECK:       entry.split:
; CHECK-NEXT:    br label [[FOR_COND:%.*]]
; CHECK:       for.cond:
; CHECK-NEXT:    [[STOREMERGE:%.*]] = phi i64 [ 0, [[ENTRY_SPLIT]] ], [ [[INC7:%.*]], [[FOR_COND]] ]
; CHECK-NEXT:    [[INC7]] = add nsw i64 [[STOREMERGE]], 1
; CHECK-NEXT:    br label [[FOR_COND]]
; CHECK:       for.body3split:
; CHECK-NEXT:    br label [[FOR_BODY3:%.*]]
; CHECK:       for.cond2.2.for.body3_crit_edge:
; CHECK-NEXT:    br label [[FOR_BODY3]]
; CHECK:       for.body3:
; CHECK-NEXT:    [[STOREMERGE_LCSSA:%.*]] = phi i64 [ undef, [[FOR_COND2_2_FOR_BODY3_CRIT_EDGE]] ], [ undef, [[FOR_BODY3SPLIT]] ]
; CHECK-NEXT:    [[ARRAYIDX:%.*]] = getelementptr inbounds [1 x i32], [1 x i32]* @c, i64 0, i64 [[STOREMERGE_LCSSA]]
; CHECK-NEXT:    ret i32* [[ARRAYIDX]]
;
entry:                                                ; preds = %entry
  br label %for.cond

for.cond:                                         ; preds = %cleanup, %entry
  %storemerge = phi i64 [ 0, %entry ], [ %inc7, %cleanup ]
  br label %for.cond2.1

for.body3:                                        ; preds = %for.cond2.2, %for.cond2.1
  %arrayidx = getelementptr inbounds [1 x i32], [1 x i32]* @c, i64 0, i64 %storemerge
  ret i32* %arrayidx

cleanup:                                          ; preds = %for.end5, %if.then
  %inc7 = add nsw i64 %storemerge, 1
  br label %for.cond

for.cond2.1:                                      ; preds = %for.cond
  br i1 true, label %for.inc.1, label %for.body3

for.inc.1:                                        ; preds = %for.end.1
  br i1 false, label %for.body.2, label %cleanup

for.body.2:                                       ; preds = %for.inc.1
  store i32 0, i32* @a, align 4
  br label %for.cond2.2

for.cond2.2:                                      ; preds = %for.body.2
  br i1 true, label %cleanup, label %for.body3
}
