//=========================================================================== //
// Copyright (c) 2016, Stephen Henry
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//=========================================================================== //

`include "multi_counter_variants_pkg.vh"

module multi_counter_variants #(
     parameter int W = 32
   , parameter int N = 32
) (
   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // Command Interface                                                       //
   //                                                                         //
   //======================================================================== //

   , input                                   cmd_pass
   , input  multi_counter_variants_pkg::op_t cmd_op
   , input  [$clog2(N)-1:0]                  cmd_id
   , input  [W-1:0]                          cmd_dat

   //======================================================================== //
   //                                                                         //
   // Status Interface                                                        //
   //                                                                         //
   //======================================================================== //

   , output logic                            busy_r

   //======================================================================== //
   //                                                                         //
   // Client Interface                                                        //
   //                                                                         //
   //======================================================================== //

   //
   , output logic                            s1_pass_r
   , output logic [W-1:0]                    s1_dat_r

   //
   , output logic                            s2_pass_r
   , output logic [W-1:0]                    s2_dat_r

   //
   , output logic                            s3_pass_r
   , output logic [W-1:0]                    s3_dat_r
);
  import multi_counter_variants_pkg::*;

  //
  typedef logic [W-1:0]       w_t;

  // ======================================================================== //
  //                                                                          //
  // Solution 1 - Flop bank update                                            //
  //                                                                          //
  // ======================================================================== //

  //
  w_t                         s1_mem_w;
  w_t [N-1:0]                 s1_mem_r;
  logic                       s1_pass_w;
  //
  logic                       s1_dat_en;
  w_t                         s1_dat_w;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : s1_PROC

      //
      unique case (cmd_op)
        OP_INIT: s1_mem_w  = cmd_dat;
        OP_INCR: s1_mem_w  = s1_mem_r [cmd_id] + 'b1;
        OP_DECR: s1_mem_w  = s1_mem_r [cmd_id] - 'b1;
        default: s1_mem_w  = '0;
      endcase // unique case (cmd_op)

      //
      s1_pass_w  = cmd_pass & (cmd_op == OP_QRY);

      //
      s1_dat_en  = s1_pass_w;

      //
      s1_dat_w   = s1_mem_r [cmd_id];

    end // block: s1_PROC

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      s1_mem_r <= '0;
    else if (cmd_pass)
      s1_mem_r [cmd_id] <= s1_mem_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      s1_pass_r <= 'b0;
    else
      s1_pass_r <= s1_pass_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (s1_dat_en)
      s1_dat_r <= s1_dat_w;

  // ======================================================================== //
  //                                                                          //
  // Solution 2 - Multi-Engines                                               //
  //                                                                          //
  // ======================================================================== //

  //
  w_t                         s2_mem_r [N-1:0];
  w_t                         s2_mem_w [N-1:0];
  logic [N-1:0]               s2_mem_en;
  //
  logic                       s2_pass_w;
  logic                       s2_dat_en;
  w_t                         s2_dat_w;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : s2_PROC

      for (int i = 0; i < N; i++) begin

        //
        unique case (cmd_op)
          OP_INIT: s2_mem_w [i] = cmd_dat;
          OP_INCR: s2_mem_w [i] = s2_mem_r [i] + 'b1;
          OP_DECR: s2_mem_w [i] = s2_mem_r [i] - 'b1;
          default: s2_mem_w [i] = s2_mem_r [i];
        endcase // unique case (cmd_op)

        case (cmd_op)
          OP_INIT,
          OP_INCR,
          OP_DECR: s2_mem_en [i]  = cmd_pass;
          default: s2_mem_en [i]  = '0;
        endcase // case (cmd_op)

      end // for (int i = 0; i < N; i++)

      //
      s2_dat_w   = s2_mem_r [cmd_op];

      //
      s2_pass_w  = cmd_pass & (cmd_op == OP_QRY);

      //
      s2_dat_en  = s2_pass_w;

    end // block: s2_PROC

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      begin
        for (int i = 0; i < N; i++)
          s2_mem_r [i] <= '0;
      end
    else
      begin
        for (int i = 0; i < N; i++)
          if (s2_mem_en [i])
            s2_mem_r [i] <= s2_mem_w [i];
      end

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      s2_pass_r <= 'b0;
    else
      s2_pass_r <= s2_pass_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (s2_dat_en)
      s2_dat_r <= s2_dat_w;


  // ======================================================================== //
  //                                                                          //
  // Solution 3 - SRAM-like forwarding                                        //
  //                                                                          //
  // ======================================================================== //

  typedef logic [$clog2(N)-1:0] id_t;
  logic                       s3_sram_prt1_en;
  logic                       s3_sram_prt1_wen;
  id_t                        s3_sram_prt1_a;
  w_t                         s3_sram_prt1_din;
  logic                       s3_sram_prt2_en;
  logic                       s3_sram_prt2_wen;
  id_t                        s3_sram_prt2_a;
  w_t                         s3_sram_prt2_dout;
  w_t                         s3_sram_r [N-1:0];
  typedef struct packed {
    op_t op;
    id_t id;
    w_t dat;
  } ucode_t;
  //
  ucode_t                     p0_ucode_w;
  ucode_t                     p0_ucode_r;
  logic                       p0_ucode_en;
  //
  ucode_t                     p1_ucode_w;
  ucode_t                     p1_ucode_r;
  logic                       p1_ucode_en;
  //
  ucode_t                     p2_ucode_w;
  ucode_t                     p2_ucode_r;
  logic                       p2_ucode_en;
  //
  ucode_t                     p3_ucode_w;
  ucode_t                     p3_ucode_r;
  logic                       p3_ucode_en;
  //
  ucode_t                     p4_ucode_w;
  ucode_t                     p4_ucode_r;
  logic                       p4_ucode_en;
  //
  logic                       p0_valid_r;
  logic                       p1_valid_r;
  logic                       p2_valid_r;
  logic                       p3_valid_r;
  logic                       p4_valid_r;
  //
  logic                       s3_pass_w;
  //
  logic                       s3_dat_en;
  w_t                         s3_dat_w;
  //
  // S0
  logic                       s0_collision;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : s3_PROC

      logic fwd__s4_to_s1;
      logic fwd__s3_to_s1;
      logic fwd__s2_to_s1;

      logic fwd__s4_to_s2;
      logic fwd__s3_to_s2;

      w_t p2_dat;

      //
      fwd__s4_to_s1   = p4_valid_r & (p1_ucode_r.id == p4_ucode_r.id);
      fwd__s3_to_s1   = p3_valid_r & (p1_ucode_r.id == p3_ucode_r.id);
      fwd__s2_to_s1   = p2_valid_r & (p1_ucode_r.id == p2_ucode_r.id);

      //
      fwd__s4_to_s2   = p4_valid_r & (p2_ucode_r.id == p4_ucode_r.id);
      fwd__s3_to_s2   = p3_valid_r & (p2_ucode_r.id == p3_ucode_r.id);

      //
      p0_ucode_en     = cmd_pass;
      p1_ucode_en     = p0_valid_r;
      p2_ucode_en     = p1_valid_r;
      p3_ucode_en     = p2_valid_r;

      //
      p0_ucode_w      = '0;
      p0_ucode_w.op   = cmd_op;
      p0_ucode_w.id   = cmd_id;
      p0_ucode_w.dat  = cmd_dat;
      p1_ucode_w      = '0;

      // EXE (S2)
      p3_ucode_w        = '0;
      case (1'b1)
        fwd__s4_to_s2: p2_dat  = p4_ucode_r.dat;
        fwd__s3_to_s2: p2_dat  = p3_ucode_r.dat;
        default:       p2_dat  = p2_ucode_r.dat;
      endcase // case (1'b1)
      unique case (p2_ucode_r.op)
        OP_INIT: p3_ucode_w.dat = p2_dat;
        OP_INCR: p3_ucode_w.dat = p2_dat + 'b1;
        OP_DECR: p3_ucode_w.dat = p2_dat - 'b1;
        default: p3_ucode_w.dat = p2_dat;
      endcase // unique case (cmd_op)

      // LKUP (S1)
      p2_ucode_w      = p1_ucode_r;
      case (1'b1)
        fwd__s4_to_s1: p2_ucode_w.dat  = p4_ucode_r.dat;
        fwd__s3_to_s1: p2_ucode_w.dat  = p3_ucode_r.dat;
        fwd__s2_to_s1: p2_ucode_w.dat  = p3_ucode_w.dat;
        default:       p2_ucode_w.dat  = s3_sram_prt2_dout;
      endcase


      // WRBK (S3)
      s3_sram_prt1_en   = p3_valid_r & p3_ucode_r.op [OP_WRITE_B];
      s3_sram_prt1_wen  = '1;
      s3_sram_prt1_a    = p3_ucode_r.op;
      s3_sram_prt1_din  = p3_ucode_r.dat;

      s0_collision      = s3_sram_prt1_en & (p0_ucode_r.op == p3_ucode_r.op);

      // LKUP (S1)
      s3_sram_prt2_en   = p1_valid_r & (~s0_collision);
      s3_sram_prt2_wen  = '0;
      s3_sram_prt2_a    = p0_ucode_r.op;

      //
      s3_pass_w         = p3_valid_r & p3_ucode_r.op [OP_OUTPUT_B];
      s3_dat_en         = s3_pass_w;
      s3_dat_w          = p3_ucode_r.dat;

    end // block: s3_PROC

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (s3_sram_prt1_en & s3_sram_prt1_wen)
      s3_sram_r [s3_sram_prt1_a] <= s3_sram_prt1_din;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (s3_sram_prt2_en & (~s3_sram_prt2_wen))
      s3_sram_prt2_dout <= s3_sram_r [s3_sram_prt2_a];

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      begin
        p0_valid_r <= '0;
        p1_valid_r <= '0;
        p2_valid_r <= '0;
        p3_valid_r <= '0;
        p4_valid_r <= '0;
      end
    else
      begin
        p0_valid_r <= cmd_pass;
        p1_valid_r <= p0_valid_r;
        p2_valid_r <= p1_valid_r;
        p3_valid_r <= p2_valid_r;
        p4_valid_r <= p3_valid_r;
      end

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    begin : ucode_reg_PROC
      if (p0_ucode_en)
        p0_ucode_r <= p0_ucode_w;
      if (p1_ucode_en)
        p1_ucode_r <= p1_ucode_w;
      if (p2_ucode_en)
        p2_ucode_r <= p2_ucode_w;
      if (p3_ucode_en)
        p3_ucode_r <= p3_ucode_w;
      if (p4_ucode_en)
        p4_ucode_r <= p4_ucode_w;
    end

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      s3_pass_r <= '0;
    else
      s3_pass_r <= s3_pass_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (s3_dat_en)
      s3_dat_r <= s3_dat_w;

endmodule // multi_counter_variants
