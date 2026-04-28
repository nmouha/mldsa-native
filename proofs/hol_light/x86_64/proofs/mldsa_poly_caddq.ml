(*
 * Copyright (c) The mldsa-native project authors
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0 OR ISC OR MIT-0
 *)

(* ========================================================================= *)
(* Functional correctness of poly_caddq:                                     *)
(* Modular reduction of polynomial coefficients from (-q, q) to [0, q)       *)
(* ========================================================================= *)

needs "x86/proofs/base.ml";;
needs "common/mldsa_specs.ml";;
needs "x86_64/proofs/mldsa_utils.ml";;

(**** print_literal_from_elf "x86_64/mldsa/mldsa_poly_caddq.o";;
 ****)

let mldsa_poly_caddq_mc = define_assert_from_elf "mldsa_poly_caddq_mc" "x86_64/mldsa/mldsa_poly_caddq.o"
(*** BYTECODE START ***)
[
  0xf3; 0x0f; 0x1e; 0xfa;  (* ENDBR64 *)
  0xba; 0x01; 0xe0; 0x7f; 0x00;
                           (* MOV (% edx) (Imm32 (word 8380417)) *)
  0x48; 0x8d; 0x87; 0x00; 0x04; 0x00; 0x00;
                           (* LEA (% rax) (%% (rdi,1024)) *)
  0xc5; 0xe9; 0xef; 0xd2;  (* VPXOR (%_% xmm2) (%_% xmm2) (%_% xmm2) *)
  0xc5; 0xf9; 0x6e; 0xca;  (* VMOVD (%_% xmm1) (% edx) *)
  0xc4; 0xe2; 0x7d; 0x58; 0xc9;
                           (* VPBROADCASTD (%_% ymm1) (%_% xmm1) *)
  0xc5; 0xed; 0x66; 0x07;  (* VPCMPGTD (%_% ymm0) (%_% ymm2) (Memop Word256 (%% (rdi,0))) *)
  0xc5; 0xfd; 0xdb; 0xc1;  (* VPAND (%_% ymm0) (%_% ymm0) (%_% ymm1) *)
  0xc5; 0xfd; 0xfe; 0x07;  (* VPADDD (%_% ymm0) (%_% ymm0) (Memop Word256 (%% (rdi,0))) *)
  0xc5; 0xfd; 0x7f; 0x07;  (* VMOVDQA (Memop Word256 (%% (rdi,0))) (%_% ymm0) *)
  0xc5; 0xed; 0x66; 0x5f; 0x20;
                           (* VPCMPGTD (%_% ymm3) (%_% ymm2) (Memop Word256 (%% (rdi,32))) *)
  0xc5; 0xe5; 0xdb; 0xd9;  (* VPAND (%_% ymm3) (%_% ymm3) (%_% ymm1) *)
  0xc5; 0xe5; 0xfe; 0x5f; 0x20;
                           (* VPADDD (%_% ymm3) (%_% ymm3) (Memop Word256 (%% (rdi,32))) *)
  0xc5; 0xfd; 0x7f; 0x5f; 0x20;
                           (* VMOVDQA (Memop Word256 (%% (rdi,32))) (%_% ymm3) *)
  0xc5; 0xed; 0x66; 0x67; 0x40;
                           (* VPCMPGTD (%_% ymm4) (%_% ymm2) (Memop Word256 (%% (rdi,64))) *)
  0xc5; 0xdd; 0xdb; 0xe1;  (* VPAND (%_% ymm4) (%_% ymm4) (%_% ymm1) *)
  0xc5; 0xdd; 0xfe; 0x67; 0x40;
                           (* VPADDD (%_% ymm4) (%_% ymm4) (Memop Word256 (%% (rdi,64))) *)
  0xc5; 0xfd; 0x7f; 0x67; 0x40;
                           (* VMOVDQA (Memop Word256 (%% (rdi,64))) (%_% ymm4) *)
  0xc5; 0xed; 0x66; 0x6f; 0x60;
                           (* VPCMPGTD (%_% ymm5) (%_% ymm2) (Memop Word256 (%% (rdi,96))) *)
  0xc5; 0xd5; 0xdb; 0xe9;  (* VPAND (%_% ymm5) (%_% ymm5) (%_% ymm1) *)
  0xc5; 0xd5; 0xfe; 0x6f; 0x60;
                           (* VPADDD (%_% ymm5) (%_% ymm5) (Memop Word256 (%% (rdi,96))) *)
  0xc5; 0xfd; 0x7f; 0x6f; 0x60;
                           (* VMOVDQA (Memop Word256 (%% (rdi,96))) (%_% ymm5) *)
  0x48; 0x81; 0xc7; 0x80; 0x00; 0x00; 0x00;
                           (* ADD (% rdi) (Imm32 (word 128)) *)
  0x48; 0x39; 0xf8;        (* CMP (% rax) (% rdi) *)
  0x75; 0xab;              (* JNE (Imm8 (word 171)) *)
  0xc3                     (* RET *)
];;
(*** BYTECODE END ***)

let mldsa_poly_caddq_tmc = define_trimmed "mldsa_poly_caddq_tmc" mldsa_poly_caddq_mc;;
let MLDSA_POLY_CADDQ_EXEC = X86_MK_EXEC_RULE mldsa_poly_caddq_mc;;
let MLDSA_POLY_CADDQ_TMC_EXEC = X86_MK_CORE_EXEC_RULE mldsa_poly_caddq_tmc;;

(* ------------------------------------------------------------------------- *)
(* Code length constants                                                     *)
(* ------------------------------------------------------------------------- *)

let LENGTH_MLDSA_POLY_CADDQ_MC =
  REWRITE_CONV[mldsa_poly_caddq_mc] `LENGTH mldsa_poly_caddq_mc`
  |> CONV_RULE (RAND_CONV LENGTH_CONV);;

(* ------------------------------------------------------------------------- *)
(* Functional specification of caddq32                                       *)
(* ------------------------------------------------------------------------- *)

(* caddq32: conditional add of Q for negative values
   Using VPCMPGTD: if 0 > x, mask = 0xFFFFFFFF, else mask = 0.
   Result = x + (mask AND Q).
   For inputs in (-Q, Q), this computes x rem Q. *)
let caddq32 = define
   `caddq32 (x:int32) =
      word_add x (word_and (if word_igt (word 0:int32) x
                            then word 0xffffffff else word 0)
                           (word 8380417))`;;

let caddq32_direct = prove
   (`!x:int32.
      ival(caddq32 x) = if ival x < &0 then ival x + &8380417 else ival x`,
    REWRITE_TAC[caddq32] THEN BITBLAST_TAC);;

let caddq32_rem = prove
   (`!x:int32. abs(ival x) < &8380417
      ==> ival(caddq32 x) = ival x rem &8380417`,
    REPEAT STRIP_TAC THEN
    REWRITE_TAC[caddq32_direct] THEN
    COND_CASES_TAC THENL [
      ONCE_REWRITE_TAC[EQ_SYM_EQ] THEN
      REWRITE_TAC[INT_REM_UNIQUE] THEN
      CONV_TAC INT_REDUCE_CONV THEN
      CONJ_TAC THENL [ASM_INT_ARITH_TAC; CONV_TAC INTEGER_RULE];
      MATCH_MP_TAC(GSYM INT_REM_LT) THEN
      ASM_INT_ARITH_TAC
    ]);;

(* ------------------------------------------------------------------------- *)
(* Core correctness theorem                                                  *)
(* ------------------------------------------------------------------------- *)

let MLDSA_POLY_CADDQ_CORRECT = prove
 (`!a x pc.
        nonoverlapping (word pc,LENGTH mldsa_poly_caddq_mc) (a,1024)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) (BUTLAST mldsa_poly_caddq_tmc) /\
                  read RIP s = word pc /\
                  C_ARGUMENTS [a] s /\
                  (!i. i < 256 ==>
                     read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
                  (!i. i < 256 ==> abs(ival(x i)) < &8380417))
             (\s. read RIP s = word(pc + 114) /\
                  (!i. i < 256 ==>
                     ival(read(memory :> bytes32(word_add a (word(4 * i)))) s) =
                     ival(x i) rem &8380417))
             (MAYCHANGE [RIP; RAX; RDX; RDI] ,,
              MAYCHANGE [ZMM0; ZMM1; ZMM2; ZMM3; ZMM4; ZMM5] ,,
              MAYCHANGE SOME_FLAGS ,,
              MAYCHANGE [memory :> bytes(a,1024)])`,
  CONV_TAC(REWRITE_CONV[LENGTH_MLDSA_POLY_CADDQ_MC]) THEN
  MAP_EVERY X_GEN_TAC [`a:int64`; `x:num->int32`; `pc:num`] THEN
  REWRITE_TAC[C_ARGUMENTS; NONOVERLAPPING_CLAUSES] THEN
  DISCH_THEN(REPEAT_TCL CONJUNCTS_THEN ASSUME_TAC) THEN

  (*** Setup: steps 1-5 (MOV, LEA, VPXOR, VMOVD, VPBROADCASTD) ***)

  ENSURES_SEQUENCE_TAC `pc + 25`
   `\s. bytes_loaded s (word pc) (BUTLAST mldsa_poly_caddq_tmc) /\
        read RDI s = a /\
        read RAX s = word_add a (word 1024) /\
        read YMM2 s = word 0 /\
        (!i. i < 256 ==>
           read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
        (!i. i < 256 ==> abs(ival(x i)) < &8380417)` THEN
  CONJ_TAC THENL
  [ENSURES_INIT_TAC "s0" THEN
   X86_STEPS_TAC MLDSA_POLY_CADDQ_TMC_EXEC (1--5) THEN
   ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
   CONV_TAC WORD_REDUCE_CONV;
   ALL_TAC] THEN

  (*** Main loop: 8 iterations, each processing 32 elements ***)

  ENSURES_WHILE_UP_TAC `8` `pc + 25` `pc + 108`
   `\i s. bytes_loaded s (word pc) (BUTLAST mldsa_poly_caddq_tmc) /\
          read RDI s = word_add a (word(128 * i)) /\
          read RAX s = word_add a (word 1024) /\
          read YMM2 s = word 0 /\
          (!j. j < 32 * i ==>
             ival(read(memory :> bytes32(word_add a (word(4 * j)))) s) =
             ival(x j) rem &8380417) /\
          (!j. 32 * i <= j /\ j < 256 ==>
             read(memory :> bytes32(word_add a (word(4 * j)))) s = x j) /\
          (!j. j < 256 ==> abs(ival(x j)) < &8380417)` THEN
  ASM_REWRITE_TAC[] THEN REPEAT CONJ_TAC THENL
  [
    (*** Initial case: invariant holds at i=0 ***)
    REWRITE_TAC[MULT_CLAUSES; LT; LE_0] THEN
    ENSURES_INIT_TAC "s0" THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[];

    (*** Loop body: one iteration, i -> i+1 ***)
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    REWRITE_TAC[ARITH_RULE `32 * (i + 1) = 32 * i + 32`] THEN
    ENSURES_INIT_TAC "s0" THEN

    (* Merge 32-bit reads into 256-bit for the 4 YMM loads *)
    MP_TAC(end_itlist CONJ (map (fun k ->
       READ_MEMORY_MERGE_CONV 3
         (subst[mk_small_numeral(128 * i + 32 * k),`n:num`]
               `read (memory :> bytes256(word_add a (word n))) s0`))
       (0--3))) THEN
    ASM_REWRITE_TAC[WORD_ADD_0] THEN
    CONV_TAC WORD_REDUCE_CONV THEN
    STRIP_TAC THEN

    MAP_EVERY (fun n ->
      X86_STEPS_TAC MLDSA_POLY_CADDQ_TMC_EXEC [n] THEN
      SIMD_SIMPLIFY_TAC[caddq32]) (1--17) THEN

    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN

    (* Split 256-bit writes back to 32-bit *)
    REPEAT(FIRST_X_ASSUM(STRIP_ASSUME_TAC o
      CONV_RULE(SIMD_SIMPLIFY_CONV[caddq32]) o
      CONV_RULE(READ_MEMORY_SPLIT_CONV 3) o
      check (can (term_match [] `read qqq s:int256 = xxx`) o concl))) THEN

    DISCARD_MATCHING_ASSUMPTIONS [`read a s = b`] THEN

    REPEAT CONJ_TAC THENL
    [CONV_TAC WORD_RULE;
     (* Processed elements: 0..32*i+31 *)
     X_GEN_TAC `j:num` THEN DISCH_TAC THEN
     ASM_CASES_TAC `j < 32 * i` THENL
     [FIRST_X_ASSUM(MP_TAC o SPEC `j:num`) THEN ASM_REWRITE_TAC[] THEN
      MATCH_MP_TAC(MESON[] `a = b ==> a = c ==> b = c`) THEN
      AP_THM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN
      CONV_TAC WORD_RULE;
      (* New elements from this iteration *)
      FIRST_X_ASSUM(MP_TAC o SPEC `j:num`) THEN
      ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
      DISCH_THEN SUBST1_TAC THEN
      MATCH_MP_TAC caddq32_rem THEN
      FIRST_X_ASSUM MATCH_MP_TAC THEN ASM_ARITH_TAC];
     (* Unprocessed elements: 32*(i+1)..255 *)
     X_GEN_TAC `j:num` THEN STRIP_TAC THEN
     FIRST_X_ASSUM(MP_TAC o SPEC `j:num`) THEN
     ANTS_TAC THENL [ASM_ARITH_TAC; ALL_TAC] THEN
     MATCH_MP_TAC(MESON[] `a = b ==> a = c ==> b = c`) THEN
     AP_THM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN AP_TERM_TAC THEN
     CONV_TAC WORD_RULE;
     ASM_REWRITE_TAC[]];

    (*** Back edge: loop test ***)
    X_GEN_TAC `i:num` THEN STRIP_TAC THEN
    VAL_INT64_TAC `128 * i` THEN
    ENSURES_INIT_TAC "s0" THEN
    X86_STEPS_TAC MLDSA_POLY_CADDQ_TMC_EXEC (1--2) THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[] THEN
    ASM_REWRITE_TAC[VAL_WORD_SUB_EQ_0] THEN
    CONV_TAC WORD_RULE;

    (*** Tail: after loop, step to RET ***)
    REWRITE_TAC[ARITH_RULE `32 * 8 = 256`; LT_REFL; LE_REFL] THEN
    ENSURES_INIT_TAC "s0" THEN
    X86_STEPS_TAC MLDSA_POLY_CADDQ_TMC_EXEC [1] THEN
    ENSURES_FINAL_STATE_TAC THEN ASM_REWRITE_TAC[]
  ]);;

(* ------------------------------------------------------------------------- *)
(* Subroutine correctness theorem (includes return)                          *)
(* ------------------------------------------------------------------------- *)

(* NOTE: This must be kept in sync with the CBMC specification
 * in mldsa/src/native/x86_64/src/arith_native_x86_64.h *)

let MLDSA_POLY_CADDQ_NOIBT_SUBROUTINE_CORRECT = prove
 (`!a x pc stackpointer returnaddress.
        nonoverlapping (word pc,LENGTH mldsa_poly_caddq_tmc) (a,1024) /\
        nonoverlapping (stackpointer,8) (a,1024)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) mldsa_poly_caddq_tmc /\
                  read RIP s = word pc /\
                  read RSP s = stackpointer /\
                  read (memory :> bytes64 stackpointer) s = returnaddress /\
                  C_ARGUMENTS [a] s /\
                  (!i. i < 256 ==>
                     read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
                  (!i. i < 256 ==> abs(ival(x i)) < &8380417))
             (\s. read RIP s = returnaddress /\
                  read RSP s = word_add stackpointer (word 8) /\
                  (!i. i < 256 ==>
                     ival(read(memory :> bytes32(word_add a (word(4 * i)))) s) =
                     ival(x i) rem &8380417))
             (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(a,1024)])`,
  X86_PROMOTE_RETURN_NOSTACK_TAC mldsa_poly_caddq_tmc MLDSA_POLY_CADDQ_CORRECT);;

let MLDSA_POLY_CADDQ_SUBROUTINE_CORRECT = prove
 (`!a x pc stackpointer returnaddress.
        nonoverlapping (word pc,LENGTH mldsa_poly_caddq_mc) (a,1024) /\
        nonoverlapping (stackpointer,8) (a,1024)
        ==> ensures x86
             (\s. bytes_loaded s (word pc) mldsa_poly_caddq_mc /\
                  read RIP s = word pc /\
                  read RSP s = stackpointer /\
                  read (memory :> bytes64 stackpointer) s = returnaddress /\
                  C_ARGUMENTS [a] s /\
                  (!i. i < 256 ==>
                     read(memory :> bytes32(word_add a (word(4 * i)))) s = x i) /\
                  (!i. i < 256 ==> abs(ival(x i)) < &8380417))
             (\s. read RIP s = returnaddress /\
                  read RSP s = word_add stackpointer (word 8) /\
                  (!i. i < 256 ==>
                     ival(read(memory :> bytes32(word_add a (word(4 * i)))) s) =
                     ival(x i) rem &8380417))
             (MAYCHANGE [RSP] ,, MAYCHANGE_REGS_AND_FLAGS_PERMITTED_BY_ABI ,,
              MAYCHANGE [memory :> bytes(a,1024)])`,
  MATCH_ACCEPT_TAC(ADD_IBT_RULE MLDSA_POLY_CADDQ_NOIBT_SUBROUTINE_CORRECT));;
