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

`include "sorted_lists_pkg.vh"
`include "dpsram_pkg.vh"

// DISABLE_FORWARDING flag enables/disables forwarding between stages 2/1 in the
// update pipeline. Updates to list state is performed in S2 and therefore
// arrives late in the cycle. The additional logic to MUX this at stage 1
// represents a critical path in the design.
//
// When DISABLE_FORWARDING is defined, the pipeline does not support
// back-to-back update commands to the same ID. Dependency/Stall logic is not
// present in the pipeline to detect this case, therefore state corrupt will
// occur.
//
`define DISABLE_FORWARDING 1

module sorted_lists
(
   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // Update                                                                  //
   //                                                                         //
   //======================================================================== //

   , input                                   upt_vld
   , input          [5:0]                    upt_id
   , input          [1:0]                    upt_op
   , input          [63:0]                   upt_key
   , input          [31:0]                   upt_size
   //
   , output logic                            upt_error_vld_r
   , output logic   [5:0]                    upt_error_id_r

   //======================================================================== //
   //                                                                         //
   // Query                                                                   //
   //                                                                         //
   //======================================================================== //

   , input                                   qry_vld
   , input          [5:0]                    qry_id
   , input          [7:0]                    qry_level
   //
   , output logic                            qry_resp_vld_r
   , output logic   [63:0]                   qry_key_r
   , output logic   [31:0]                   qry_size_r
   , output logic                            qry_error_r
   , output logic   [7:0]                    qry_listsize_r

   //======================================================================== //
   //                                                                         //
   // Notify                                                                  //
   //                                                                         //
   //======================================================================== //

   , output logic                            ntf_vld_r
   , output logic   [5:0]                    ntf_id_r
   , output logic   [63:0]                   ntf_key_r
   , output logic   [31:0]                   ntf_size_r
);
  import sorted_lists_pkg::*;

  // Enumeration denoting permissible Update Opcodes.
  //
  typedef enum logic [1:0]  { OP_CLEAR    = 2'b00,
                              OP_ADD      = 2'b01,
                              OP_DELETE   = 2'b10,
                              OP_REPLACE  = 2'b11 } op_t ;

  //
  typedef logic [N-1:0] n_d_t;
  typedef logic [$clog2(N)-1:0] n_t;
  typedef logic [5:0] id_t;
  typedef logic [7:0] listsize_t;
  typedef logic [7:0] level_t;

  // Structure denoting an Update command
  //
  typedef struct packed {
    id_t id;
    op_t op;
    key_t key;
    size_t size;
  } upt_t;

  // Update pipeline micro-code.
  //
  typedef struct packed {
    upt_t u;
    table_state_t t;
    logic        error;
  } ucode_upt_t;

  // Query pipeline micro-code.
  //
  typedef struct packed {
    id_t id;
    level_t level;
    table_state_t t;
  } ucode_qry_t;

  //
  typedef struct packed {
    logic vld;
    id_t id;
    level_t level;
  } qry_delay_pipe_t;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  ucode_upt_t                           ucode_upt_0_r;
  ucode_upt_t                           ucode_upt_0_w;
  //
  ucode_upt_t                           ucode_upt_1_r;
  ucode_upt_t                           ucode_upt_1_w;
  //
  ucode_upt_t                           ucode_upt_2_r;
  ucode_upt_t                           ucode_upt_2_w;
  //
  ucode_upt_t                           ucode_upt_3_r;
  ucode_upt_t                           ucode_upt_3_w;
  //
  ucode_qry_t                           ucode_qry_0_r;
  ucode_qry_t                           ucode_qry_0_w;
  //
  ucode_qry_t                           ucode_qry_1_r;
  ucode_qry_t                           ucode_qry_1_w;
  //
  ucode_qry_t                           ucode_qry_2_r;
  ucode_qry_t                           ucode_qry_2_w;
  //
  `DPSRAM_SIGNALS(qry_table_, $bits(table_state_t), $clog2(M));
  `DPSRAM_SIGNALS(upt_table_, $bits(table_state_t), $clog2(M));
  //
  logic                                 qry_resp_vld_w;
  key_t                                 qry_key_w;
  size_t                                qry_size_w;
  logic                                 qry_error_w;
  listsize_t                            qry_listsize_w;
  //
  logic                                 ntf_vld_w;
  id_t                                  ntf_id_w;
  key_t                                 ntf_key_w;
  size_t                                ntf_size_w;
  logic                                 ntf_error_w;
  //
  logic                                 upt_error_vld_w;
  id_t                                  upt_error_id_w;
  //
  logic [3:0]                           upt_pipe_vld_r;
  logic [3:0]                           upt_pipe_vld_w;
  //
  logic [2:0]                           qry_pipe_vld_r;
  logic [2:0]                           qry_pipe_vld_w;
  //
  n_d_t                                 ucode_upt_2_t_vld;
  n_d_t                                 ucode_upt_3_t_vld;
  logic [$clog2(N):0]                   ucode_upt_3_t_popcnt;
  n_t                                   vld_not_set_e;
  n_d_t                                 ucode_upt_2_t_hit;
  n_t                                   hit_e;
  n_t                                   ucode_upt_3_hit_e_r;
  //
  qry_delay_pipe_t                      qry_delay_pipe_in;
  qry_delay_pipe_t                      qry_delay_pipe_out_r;
  //
  table_state_t                         ucode_qry_X_sorted_r;
  n_d_t                                 ucode_qry_X_valid;
  logic [$clog2(N):0]                   ucode_qry_X_valid_popcnt;
  entry_t                               ucode_qry_X_entry;
  //
  table_state_t                         ucode_upt_2_t_fwd;
  //
  table_state_t                         upt_table_wrbk_r;
  table_state_t                         upt_table_wrbk_w;
  logic                                 upt_table_wrbk_vld_r;
  logic                                 upt_table_wrbk_vld_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : update_exe_fwd_PROC

      //
      case ({     upt_pipe_vld_r [3]
               & (ucode_upt_2_r.u.id == ucode_upt_3_r.u.id)
            })
        1'b1:    ucode_upt_2_t_fwd  = ucode_upt_3_r.t;
        default: ucode_upt_2_t_fwd  = ucode_upt_2_r.t;
      endcase

      //
      ucode_upt_2_t_vld = '0;
      for (int i = 0; i < N; i++)
        ucode_upt_2_t_vld [i]  = ucode_upt_2_t_fwd.e[i].vld;

      //
      ucode_upt_2_t_hit = '0;
      for (int i = 0; i < N; i++)
        ucode_upt_2_t_hit [i] = ucode_upt_2_t_fwd.e[i].vld &&
                   (ucode_upt_2_t_fwd.e[i].key == ucode_upt_2_r.u.key);
    end // block: update_exe_fwd_PROC


  // ------------------------------------------------------------------------ //
  // Stage 2 of the Update pipeline.
  //
  // Update command execution takes place at this point and the new list state
  // constructed (to be written back in Stage 3).
  //
  always_comb
    begin : update_exe_PROC

      //
      ucode_upt_3_w    = ucode_upt_2_r;
      ucode_upt_3_w.t  = ucode_upt_2_t_fwd;

      //
      case (ucode_upt_2_r.u.op)

        // CLEAR command: invalidate all state associated with the currently
        // addressed List.
        //
        OP_CLEAR: begin
          ucode_upt_3_w.t  = '0;
          for (int i = 0; i < N; i++)
            ucode_upt_3_w.t.e[i].key = '0;
        end

        // ADD command: append a new {KEY, SIZE} pair to the List state. If the
        // List is full, no modification is made to state, the operation is
        // killed and and error raised.
        //
        OP_ADD: begin
          ucode_upt_3_w.error  = '0;
          ucode_upt_3_w.error |= (ucode_upt_2_t_vld == '1);

          // Defeat any consequent updates to machine state.
          if (!ucode_upt_3_w.error) begin
            entry_t e;
            e.vld                              = '1;
            e.key                              = ucode_upt_2_r.u.key;
            e.size                             = ucode_upt_2_r.u.size;
            ucode_upt_3_w.t.e [vld_not_set_e]  = e;
          end
        end // case: OP_ADD

        // DELETE command: a given {KEY, SIZE} pair is invalidated based upon a
        // match to the commands KEY operand. If the KEY is not present in the
        // List, the command is killed and an error signalled. On error, no
        // modification is made to List state.
        //
        OP_DELETE: begin
          ucode_upt_3_w.error  = '0;
          ucode_upt_3_w.error |= (ucode_upt_2_t_hit == '0);

          if (!ucode_upt_3_w.error) begin
            ucode_upt_3_w.t.e [hit_e].vld  = '0;
            ucode_upt_3_w.t.e [hit_e].key  = '0;
          end
        end

        // REPLACE command: An existing {KEY, SIZE} pair is modified such that
        // its KEY is replaced with the operand. If the KEY is not present in
        // the List, the command is killed and an error raised. On error, no
        // modification is made to List state.
        //
        OP_REPLACE: begin
          ucode_upt_3_w.error  = '0;
          ucode_upt_3_w.error |= (ucode_upt_2_t_hit == '0);

          if (!ucode_upt_3_w.error)
            ucode_upt_3_w.t.e [hit_e].size = ucode_upt_2_r.u.size;
        end
      endcase

    end // block: update_exe_PROC


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : ucode_upt_3_PROC

      //
      ucode_upt_3_t_vld = '0;
      for (int i = 0; i < N; i++)
        ucode_upt_3_t_vld [i]  = ucode_upt_3_r.t.e[i].vld;

    end // block: ucode_upt_3_PROC


  // ------------------------------------------------------------------------ //
  // Notification
  //
  // Notifications are emitted to some external agent based when the occupancy
  // of the currently addressed List falls to zero entries. This occurs on one
  // of two occasions:
  //
  //   1) The LIST is cleared
  //
  //   2) An entry in the list is deleted and it is the only entry in the
  //      list.
  //
  // Notifications are not raised iff the current command has been killed
  // because of an upstream error.
  //
  always_comb
    begin : ntf_PROC

      //
      ntf_vld_w   =    upt_pipe_vld_r [3]
                    & (    (ucode_upt_3_r.u.op == OP_CLEAR)
                        || (   (ucode_upt_3_t_popcnt == 'b1)
                             & (ucode_upt_3_r.u.op == OP_DELETE)
                             & (~ucode_upt_3_r.error)
                           )
                      )
                  ;
      ntf_id_w    = ucode_upt_3_r.u.id;
      ntf_key_w   = ucode_upt_3_r.t.e [ucode_upt_3_hit_e_r].key;
      ntf_size_w  = ucode_upt_3_r.t.e [ucode_upt_3_hit_e_r].size;

    end // block: ntf_PROC


  // ------------------------------------------------------------------------ //
  // Update Pipeline
  //
  // Ancillary and control logic for the update pipeline. Forwarding is present
  // at Stage 1 although this can be additionally qualified based upon the
  // DISABLE_FORWARDING parameter.
  //
  always_comb
    begin : update_pipe_PROC

      //
      upt_pipe_vld_w        = { upt_pipe_vld_r [2:0], upt_vld };

      //
      ucode_upt_0_w         = '0;
      ucode_upt_0_w.u.id    = upt_id;
      ucode_upt_0_w.u.op    = op_t'(upt_op);
      ucode_upt_0_w.u.key   = upt_key;
      ucode_upt_0_w.u.size  = upt_size;

      //
      ucode_upt_1_w         = ucode_upt_0_r;

      //
      ucode_upt_2_w         = ucode_upt_1_r;
      casez ({
`ifdef DISABLE_FORWARDING
                    1'b0
`else
                    upt_pipe_vld_r [2]
                 & (ucode_upt_1_r.u.id == ucode_upt_2_r.u.id)
`endif
               ,    upt_pipe_vld_r [3]
                 & (ucode_upt_1_r.u.id == ucode_upt_3_r.u.id)
               , upt_table_wrbk_vld_r
             })
`ifndef DISABLE_FORWARDING
        3'b1??:  ucode_upt_2_w.t  = ucode_upt_3_w.t;
`endif
        3'b01?:  ucode_upt_2_w.t  = ucode_upt_3_r.t;
        3'b001:  ucode_upt_2_w.t  = upt_table_wrbk_r;
        default: ucode_upt_2_w.t  = upt_table_dout1;
      endcase // casez ({})
    end


  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      ucode_qry_X_valid = '0;
      for (int i = 0; i < N; i++)
        ucode_qry_X_valid [i] = ucode_qry_X_sorted_r.e [i].vld;

    end


  // ------------------------------------------------------------------------ //
  // Query Pipeline
  //
  // Ancillary and control logic for the Query pipeline. The Query pipeline is
  // extended using a standard delay pipe structure to account for additional
  // latency through the sorting network.
  //
  always_comb
    begin : qry_pipe_PROC

      //
      qry_pipe_vld_w       = { qry_pipe_vld_r [1:0], qry_vld };

      //
      ucode_qry_0_w        = '0;
      ucode_qry_0_w.id     = qry_id;
      ucode_qry_0_w.level  = qry_level;

      //
      ucode_qry_1_w        = ucode_qry_0_r;

      //
      ucode_qry_2_w        = ucode_qry_1_r;
      ucode_qry_2_w.t      = qry_table_dout1;

      //
      qry_delay_pipe_in    = '{qry_pipe_vld_r [2],
                               ucode_qry_2_r.id,
                               ucode_qry_2_r.level};

    end // block: qry_pipe_PROC


  // ------------------------------------------------------------------------ //
  // Query Result Selection Mux.
  //
  // The post-sort selection operation is carried out. Associated state with
  // that Entry is passed to the Query Response interface.
  //
  always_comb
    begin

      //
      ucode_qry_X_entry    = '0;
      for (int i = 0; i < N; i++)
        ucode_qry_X_entry |= (qry_delay_pipe_out_r.level == level_t'(i))
          ? ucode_qry_X_sorted_r.e[i] : '0;

      //
      qry_resp_vld_w       = qry_delay_pipe_out_r.vld;
      qry_key_w            = ucode_qry_X_entry.key;
      qry_size_w           = ucode_qry_X_entry.size;
      qry_error_w          = (~ucode_qry_X_entry.vld);
      qry_listsize_w       = listsize_t'(ucode_qry_X_valid_popcnt);

    end // block: qry_pipe_PROC


  // ------------------------------------------------------------------------ //
  // State Table (SRAM) Access Logic
  //
  // The Query and Update tables are implemented. Both tables are read by their
  // respective pipeline. The table is written by the Update pipeline. The Query
  // pipeline never writes to table state.
  //
  // Ports are fixed function and are dedicated to either read or write.
  //
  always_comb
    begin : qry_table_w_PROC

      upt_table_wrbk_vld_w  =   upt_pipe_vld_r [0]
                              & upt_pipe_vld_r [3]
                              & (ucode_upt_0_r.u.id == ucode_upt_3_r.u.id)
                            ;
      upt_table_wrbk_w      = ucode_upt_3_r.t;

      // RD port
      //
      upt_table_en1         = upt_pipe_vld_r [0] & (~upt_table_wrbk_vld_w);
      upt_table_wen1        = '0;
      upt_table_addr1       = ucode_upt_0_r.u.id;
      upt_table_din1        = '0;

      // WR port
      //
      upt_table_en2         = upt_pipe_vld_r [3];
      upt_table_wen2        = '1;
      upt_table_addr2       = ucode_upt_3_r.u.id;
      upt_table_din2        = ucode_upt_3_r.t;

      // RD port
      //
      qry_table_en1         = qry_pipe_vld_r [0];
      qry_table_wen1        = '0;
      qry_table_addr1       = ucode_qry_0_r.id;
      qry_table_din1        = '0;

      // WR port
      //
      qry_table_en2         = upt_table_en2;
      qry_table_wen2        = upt_table_wen2;
      qry_table_addr2       = upt_table_addr2;
      qry_table_din2        = upt_table_din2;

    end // block: qry_table_w_PROC


  // ======================================================================== //
  //                                                                          //
  // Sequential Logic                                                         //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      upt_pipe_vld_r <= 'b0;
    else
      upt_pipe_vld_r <= upt_pipe_vld_w;


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk) begin : ucode_upt_reg_PROC

    if (upt_pipe_vld_w [0])
      ucode_upt_0_r <= ucode_upt_0_w;

    if (upt_pipe_vld_w [1])
      ucode_upt_1_r <= ucode_upt_1_w;

    if (upt_pipe_vld_w [2])
      ucode_upt_2_r <= ucode_upt_2_w;

    if (upt_pipe_vld_w [3])
      ucode_upt_3_r <= ucode_upt_3_w;

  end // block: ucode_upt_reg_PROC


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      qry_pipe_vld_r <= 'b0;
    else
      qry_pipe_vld_r <= qry_pipe_vld_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk) begin : ucode_qry_reg_PROC

    if (qry_pipe_vld_w [0])
      ucode_qry_0_r <= ucode_qry_0_w;

    if (qry_pipe_vld_w [1])
      ucode_qry_1_r <= ucode_qry_1_w;

    if (qry_pipe_vld_w [2])
      ucode_qry_2_r <= ucode_qry_2_w;

  end // block: ucode_qry_reg_PROC


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      qry_resp_vld_r <= 'b0;
    else
      qry_resp_vld_r <= qry_resp_vld_w;


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (qry_resp_vld_w) begin
      qry_key_r      <= qry_key_w;
      qry_size_r     <= qry_size_w;
      qry_error_r    <= qry_error_w;
      qry_listsize_r <= qry_listsize_w;
    end


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      ntf_vld_r <= 'b0;
    else
      ntf_vld_r <= ntf_vld_w;


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (ntf_vld_w) begin
      ntf_id_r   <= ntf_id_w;
      ntf_key_r  <= ntf_key_w;
      ntf_size_r <= ntf_size_w;
    end


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      upt_error_vld_r <= '0;
    else
      upt_error_vld_r <= upt_error_vld_w;


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (upt_error_vld_w)
      upt_error_id_r <= upt_error_id_w;


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      upt_table_wrbk_vld_r <= '0;
    else
      upt_table_wrbk_vld_r <= upt_table_wrbk_vld_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (upt_table_wrbk_vld_w)
      upt_table_wrbk_r <= upt_table_wrbk_w;


  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    ucode_upt_3_hit_e_r <= hit_e;


  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  popcnt #(.W(N)) u_ntf (
    //
      .x                      (ucode_upt_3_t_vld       )
    //
    , .y                      (ucode_upt_3_t_popcnt    )
  );


  // ------------------------------------------------------------------------ //
  //
  popcnt #(.W(N)) u_popcnt (
    //
      .x                      (ucode_qry_X_valid)
    //
    , .y                      (ucode_qry_X_valid_popcnt)
  );


  // ------------------------------------------------------------------------ //
  //
  delay_pipe #(.W($bits(qry_delay_pipe_t)), .N(3)) u_qry_delay_pipe (
    //
      .clk                    (clk                 )
    , .rst                    (rst                 )
    //
    , .in                     (qry_delay_pipe_in   )
    , .out_r                  (qry_delay_pipe_out_r)
  );


  // ------------------------------------------------------------------------ //
  //
  ffs #(.W(N), .OPT_FIND_FIRST_ZERO(1'b1)) u_ffs (
    //
      .x                      (ucode_upt_2_t_vld  )
    //
    , .y                      ()
    , .n                      (vld_not_set_e      )
  );


  // ------------------------------------------------------------------------ //
  //
  encoder #(.W(N)) u_encoder (
    //
      .x                      (ucode_upt_2_t_hit   )
    //
    , .n                      (hit_e               )
  );


  // ------------------------------------------------------------------------ //
  //
  sorting_network u_sorting_network (
    //
      .clk                    (clk                 )
    , .rst                    (rst                 )
    //
    , .unsorted_valid         (qry_pipe_vld_r [2]  )
    , .unsorted               (ucode_qry_2_r.t     )
    //
    , .sorted_r               (ucode_qry_X_sorted_r)
  );


  // ------------------------------------------------------------------------ //
  //
  dpsrams #(.W($bits(table_state_t)), .N(M)) u_upt_table (
    //
      .clk                    (clk                )
    //
    , .en1                    (upt_table_en1      )
    , .wen1                   (upt_table_wen1     )
    , .addr1                  (upt_table_addr1    )
    , .din1                   (upt_table_din1     )
    , .dout1                  (upt_table_dout1    )
    //
    , .en2                    (upt_table_en2      )
    , .wen2                   (upt_table_wen2     )
    , .addr2                  (upt_table_addr2    )
    , .din2                   (upt_table_din2     )
    , .dout2                  (upt_table_dout2    )
  );


  // ------------------------------------------------------------------------ //
  //
  dpsrams #(.W($bits(table_state_t)), .N(M)) u_qry_table (
    //
      .clk                    (clk                )
    //
    , .en1                    (qry_table_en1      )
    , .wen1                   (qry_table_wen1     )
    , .addr1                  (qry_table_addr1    )
    , .din1                   (qry_table_din1     )
    , .dout1                  (qry_table_dout1    )
    //
    , .en2                    (qry_table_en2      )
    , .wen2                   (qry_table_wen2     )
    , .addr2                  (qry_table_addr2    )
    , .din2                   (qry_table_din2     )
    , .dout2                  (qry_table_dout2    )
  );

endmodule
