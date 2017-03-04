//========================================================================== //
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
//========================================================================== //

`include "pd_pkg.vh"

module linked_list_queue_cntrl #(
parameter int W = 32,
parameter int N = 16,
parameter int M = 128
)
(
   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

   //
     input                                        clk
   , input                                        rst

   //======================================================================== //
   //                                                                         //
   // Command Interface                                                       //
   //                                                                         //
   //======================================================================== //

   , input                                        cmd_pass
   , input                                        cmd_push
   , input        [W-1:0]                         cmd_data
   , input        [$clog2(N)-1:0]                 cmd_ctxt
   //
   , output logic                                 cmd_accept

   //======================================================================== //
   //                                                                         //
   // Lookup Interface                                                        //
   //                                                                         //
   //======================================================================== //

   , output logic                                 lkup_pass_r
   , output logic                                 lkup_rnw_r
   , output logic [W-1:0]                         lkup_data_r
   , output logic [$clog2(M)-1:0]                 lkup_addr_r
   , output logic                                 lkup_empty_r

   //======================================================================== //
   //                                                                         //
   // Status Interface                                                        //
   //                                                                         //
   //======================================================================== //

   , output logic                                 full_r
   , output logic [N-1:0]                         empty_r
);

  `define ENCODE_W M
  `define ENCODE_SUFFIX M
  `include "encode.vh"
  `undef ENCODE_W
  `undef ENCODE_SUFFIX

  `define FFS_W M
  `define FFS_SUFFIX M
  `include "ffs.vh"
  `undef ENCODE_W
  `undef ENCODE_SUFFIX

  // ======================================================================== //
  //                                                                          //
  // Typedefs                                                                 //
  //                                                                          //
  // ======================================================================== //

  typedef logic [N-1:0] n_t;
  typedef logic [M-1:0] m_t;
  //
  localparam int CTXT_W = $clog2(N);
  typedef logic [CTXT_W-1:0] ctxt_t;
  //
  localparam int WORD_W = W;
  typedef logic [WORD_W-1:0] w_t;
  //
  localparam int ADDR_W  = $clog2(M);
  typedef logic [ADDR_W-1:0] addr_t;

  //
  typedef struct packed {
    logic        empty;
    addr_t       head;
    addr_t       tail;
  } state_t;
  localparam int STATE_W = $bits(state_t);

  typedef struct packed {
    state_t      state;
    addr_t       link;
  } ucode_fwd_t;

  //
  typedef struct packed {
    // Constants:
    logic        push;
    ctxt_t       ctxt;
    w_t          data;
    // Forwarded:
    state_t      state;
    // Temporaries:
    addr_t       addr;
    addr_t       link;
  } ucode_t;
  localparam int UCODE_W = $bits(ucode_t);

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  `DPSRAM_SIGNALS(state_table_, STATE_W, $clog2(N));
  `SPSRAM_SIGNALS(queue_table_, ADDR_W, $clog2(M));

  //
  ucode_t                     ucode_s0_w;
  ucode_t                     ucode_s0_r;
  logic                       ucode_s0_en;
  //
  ucode_t                     ucode_s1_w;
  ucode_t                     ucode_s1_r;
  logic                       ucode_s1_en;
  //
  ucode_t                     ucode_s2_w;
  ucode_t                     ucode_s2_r;
  logic                       ucode_s2_en;
  //
  ucode_t                     ucode_s3_w;
  ucode_t                     ucode_s3_r;
  logic                       ucode_s3_en;
  //
  ucode_t                     ucode_s4_w;
  ucode_t                     ucode_s4_r;
  logic                       ucode_s4_en;
  //
  logic                       valid_s0_w;
  logic                       valid_s0_r;
  //
  logic                       valid_s1_w;
  logic                       valid_s1_r;
  //
  logic                       valid_s2_w;
  logic                       valid_s2_r;
  //
  logic                       valid_s3_w;
  logic                       valid_s3_r;
  //
  logic                       valid_s4_w;
  logic                       valid_s4_r;
  //
  logic                       s0_hazard;
  logic                       stall_s0;
  logic                       adv_s0;
  //
  logic                       full_w;
  n_t                         empty_w;
  //
  state_t                     state_s2;
  state_t                     state_s3;
  //
  logic                       state_table_collision_w;
  logic                       state_table_collision_r;
  //
  logic                       state_table_collision_dat_en;
  state_t                     state_table_collision_dat_w;
  state_t                     state_table_collision_dat_r;
  //
  logic                       fp_alloc;
  addr_t                      fp_alloc_id;
  logic                       fp_clear;
  addr_t                      fp_clear_id;
  m_t                         fp_state_r;
  logic                       fp_all_alloc_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : fp_PROC

      fp_alloc     = (cmd_pass & cmd_accept & cmd_push);
      fp_alloc_id  = EncodeM(FFSM(~fp_state_r));

      fp_clear     = valid_s4_r;
      fp_clear_id  = ucode_s4_r.link;

    end // block: fp_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : pipe_PROC

      // A one-cycle stall is incurred on back-to-back pops to the same queue
      // context.
      //
      s0_hazard         =   valid_s1_r
                          & (~ucode_s0_r.push)
                          & (~ucode_s1_r.push)
                          & (ucode_s0_r.ctxt == ucode_s1_r.ctxt)
                        ;
      stall_s0          = valid_s0_r & s0_hazard;
      adv_s0            = valid_s0_r & (~stall_s0);

      //
      ucode_s0_w        = '0;
      ucode_s0_w.push   = cmd_push;
      ucode_s0_w.data   = cmd_data;
      ucode_s0_w.ctxt   = cmd_ctxt;
      ucode_s0_w.link   = fp_alloc_id;
      //
      ucode_s1_w        = ucode_s0_r;
      //
      ucode_s2_w        = ucode_s1_r;
      ucode_s2_w.state  = state_s2;
      ucode_s2_w.addr   = ucode_s1_r.push ? state_s2.head : state_s2.tail;
      ucode_s2_w.link   = ucode_s1_r.push ? ucode_s1_r.link : state_s2.tail;
      //
      ucode_s3_w        = ucode_s2_r;
      ucode_s3_w.state  = state_s3;
      //
      ucode_s4_w        = ucode_s3_r;
      if (ucode_s3_r.push) begin
        ucode_s4_w.state.head  = ucode_s3_r.link;
      end else begin
        ucode_s4_w.link        = ucode_s4_r.state.tail;
        ucode_s4_w.state.tail  = queue_table_dout;
      end

      //
      valid_s0_w        = cmd_pass & (~stall_s0);
      valid_s1_w        = valid_s0_r & (~stall_s0);
      valid_s2_w        = valid_s1_r;
      valid_s3_w        = valid_s2_r;
      valid_s4_w        = valid_s3_r;

    end // block: pipe_PROC


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : state_table_PROC

      //
      state_table_csn1  = ~(adv_s0 & (~state_table_collision_w));
      state_table_wen1  = '1;
      state_table_oen1  = (~adv_s0);
      state_table_di1   = '0;
      state_table_a1    = ucode_s0_r.ctxt;

      //
      state_table_csn2  = (~valid_s4_r);
      state_table_wen2  = '0;
      state_table_oen2  = (~valid_s4_r);
      state_table_di2   = '0;
      state_table_a2    = ucode_s4_r.ctxt;

    end // block: state_table_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : queue_table_PROC

      queue_table_csn  = ~(valid_s3_r);
      queue_table_wen  = ~(ucode_s3_r.push);
      queue_table_oen  = ~(valid_s3_r & (~ucode_s3_r.push));
      queue_table_a    =   ucode_s3_r.link;
      queue_table_di   =   ucode_s3_r.link;

    end // block: queue_table_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : state_table_collision_PROC

      state_table_collision_w       =   valid_s4_r
                                      & (~rst)
                                      & (ucode_s4_r.ctxt == ucode_s1_r.ctxt)
                                    ;

      //
      state_table_collision_dat_en  = valid_s4_r & state_table_collision_w;
      state_table_collision_dat_w   = state_table_di2;

    end // block: state_table_collision_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : forwarding_PROC

      logic fwd__state_s4_to_s2;
      logic fwd__state_s3_to_s2;
      logic fwd__collision_to_s2;
      //
      logic fwd__state_s4_to_s3;

      fwd__state_s4_to_s2   = valid_s4_r & (ucode_s4_r.ctxt == ucode_s2_r.ctxt);
      fwd__state_s3_to_s2   = valid_s3_r & (ucode_s4_r.ctxt == ucode_s3_r.ctxt);
      fwd__collision_to_s2  = state_table_collision_r;

      case (1'b1)
        fwd__state_s3_to_s2:  state_s2  = ucode_s3_r.state;
        fwd__state_s4_to_s2:  state_s2  = ucode_s4_r.state;
        fwd__collision_to_s2: state_s2  = state_table_collision_dat_r;
        default:              state_s2  = state_table_dout1;
      endcase // case (1'b1)

      case (1'b1)
        fwd__state_s4_to_s3:  state_s3  = ucode_s4_w.state;
        default:              state_s3  = ucode_s3_r.state;
      endcase

    end // block: forwarding_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : status_PROC

      //
      full_w        = (~rst) & fp_all_alloc_w;

      //
      casez ({rst})
        1'b1:    empty_w  = '1;
        default: empty_w = empty_r;
      endcase

    end // block: status_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : lkup_PROC

      lkup_pass_r   = valid_s4_r;
      lkup_rnw_r    = (~ucode_s4_r.push);
      lkup_data_r   = ucode_s4_r.data;
      lkup_addr_r   = ucode_s4_r.link;
      lkup_empty_r  = '0;

    end // block: lkup_PROC

  // ======================================================================== //
  //                                                                          //
  // Sequential Logic                                                         //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (ucode_s0_en)
      ucode_s0_r <= ucode_s0_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (ucode_s1_en)
      ucode_s1_r <= ucode_s1_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (ucode_s2_en)
      ucode_s2_r <= ucode_s2_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (ucode_s3_en)
      ucode_s3_r <= ucode_s3_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (ucode_s4_en)
      ucode_s4_r <= ucode_s4_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    full_r <= full_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    empty_r <= empty_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    state_table_collision_r <= state_table_collision_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (state_table_collision_dat_en)
      state_table_collision_dat_r <= state_table_collision_dat_w;

  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  bitset #(.N(M)) u_fp (
      .clk                    (clk                )
    , .rst                    (rst                )
    , .alloc                  (fp_alloc           )
    , .alloc_id               (fp_alloc_id        )
    , .clear                  (fp_clear           )
    , .clear_id               (fp_clear_id        )
    , .state_r                (fp_state_r         )
    , .all_alloc_w            (fp_all_alloc_w     )
    , .all_clear_w            ()
  );

  // ------------------------------------------------------------------------ //
  //
  dpsram #(.W(STATE_W), .N(N))u_state_table (
    // Port 1
      .clk1                   (clk                )
    , .csn1                   (state_table_csn1   )
    , .wen1                   (state_table_wen1   )
    , .oen1                   (state_table_oen1   )
    , .a1                     (state_table_a1     )
    , .di1                    (state_table_di1    )
    , .dout1                  (state_table_dout1  )

    // Port 2
    , .clk2                   (clk                )
    , .csn2                   (state_table_csn2   )
    , .wen2                   (state_table_wen2   )
    , .oen2                   (state_table_oen2   )
    , .a2                     (state_table_a2     )
    , .di2                    (state_table_di2    )
    , .dout2                  (state_table_dout2  )
  );

  // ------------------------------------------------------------------------ //
  //
  spsram #(.W(ADDR_W), .N(M)) u_queue_table (
      .clk                    (clk                )
    , .csn                    (queue_table_csn    )
    , .wen                    (queue_table_wen    )
    , .oen                    (queue_table_oen    )
    , .a                      (queue_table_a      )
    , .di                     (queue_table_di     )
    , .dout                   (queue_table_dout   )
  );

endmodule // linked_list_fifo
