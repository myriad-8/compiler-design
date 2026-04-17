; ModuleID = 'Expresso'
source_filename = "Expresso"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@0 = private unnamed_addr constant [17 x i8] c"Enter a number: \00", align 1
@1 = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@2 = private unnamed_addr constant [16 x i8] c"Enter another: \00", align 1
@3 = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
@4 = private unnamed_addr constant [18 x i8] c"The sum is:  %ld\0A\00", align 1
@5 = private unnamed_addr constant [35 x i8] c"Sum is Even and > 10. Value:  %ld\0A\00", align 1
@6 = private unnamed_addr constant [29 x i8] c"Sum is Even but small:  %ld\0A\00", align 1
@7 = private unnamed_addr constant [25 x i8] c"Sum is Odd! Value:  %ld\0A\00", align 1
@8 = private unnamed_addr constant [31 x i8] c"Starting countdown from:  %ld\0A\00", align 1
@9 = private unnamed_addr constant [17 x i8] c"Countdown:  %ld\0A\00", align 1

declare i32 @printf(ptr, ...)

declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %isEven = alloca i64, align 8
  %c = alloca i64, align 8
  %b = alloca i64, align 8
  %a = alloca i64, align 8
  %0 = call i32 (ptr, ...) @printf(ptr @0)
  %1 = call i32 (ptr, ...) @scanf(ptr @1, ptr %a)
  %2 = call i32 (ptr, ...) @printf(ptr @2)
  %3 = call i32 (ptr, ...) @scanf(ptr @3, ptr %b)
  %b1 = load i64, ptr %b, align 8
  %a2 = load i64, ptr %a, align 8
  %addtmp = add i64 %a2, %b1
  store i64 %addtmp, ptr %c, align 8
  %c3 = load i64, ptr %c, align 8
  %andtmp = and i64 %c3, 1
  store i64 %andtmp, ptr %isEven, align 8
  %c4 = load i64, ptr %c, align 8
  %4 = call i32 (ptr, ...) @printf(ptr @4, i64 %c4)
  %isEven5 = load i64, ptr %isEven, align 8
  %eqtmp = icmp eq i64 %isEven5, 0
  %5 = zext i1 %eqtmp to i64
  %ifcond = icmp ne i64 %5, 0
  br i1 %ifcond, label %then, label %else

then:                                             ; preds = %entry
  %c9 = load i64, ptr %c, align 8
  %gttmp = icmp sgt i64 %c9, 10
  %6 = zext i1 %gttmp to i64
  %ifcond10 = icmp ne i64 %6, 0
  br i1 %ifcond10, label %then6, label %else7

else:                                             ; preds = %entry
  %c13 = load i64, ptr %c, align 8
  %7 = call i32 (ptr, ...) @printf(ptr @7, i64 %c13)
  br label %ifcont

ifcont:                                           ; preds = %else, %ifcont8
  %b14 = load i64, ptr %b, align 8
  %8 = call i32 (ptr, ...) @printf(ptr @8, i64 %b14)
  br label %w.cond

then6:                                            ; preds = %then
  %c11 = load i64, ptr %c, align 8
  %9 = call i32 (ptr, ...) @printf(ptr @5, i64 %c11)
  br label %ifcont8

else7:                                            ; preds = %then
  %c12 = load i64, ptr %c, align 8
  %10 = call i32 (ptr, ...) @printf(ptr @6, i64 %c12)
  br label %ifcont8

ifcont8:                                          ; preds = %else7, %then6
  br label %ifcont

w.cond:                                           ; preds = %w.body, %ifcont
  %b15 = load i64, ptr %b, align 8
  %gttmp16 = icmp sgt i64 %b15, 0
  %11 = zext i1 %gttmp16 to i64
  %w.check = icmp ne i64 %11, 0
  br i1 %w.check, label %w.body, label %w.after

w.body:                                           ; preds = %w.cond
  %b17 = load i64, ptr %b, align 8
  %12 = call i32 (ptr, ...) @printf(ptr @9, i64 %b17)
  %b18 = load i64, ptr %b, align 8
  %subtmp = sub i64 %b18, 1
  store i64 %subtmp, ptr %b, align 8
  br label %w.cond

w.after:                                          ; preds = %w.cond
  ret i32 0
}
