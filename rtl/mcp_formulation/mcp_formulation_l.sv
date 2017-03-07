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

module mcp_formulation_l #(

  // ======================================================================= //
  //                                                                         //
  //  Parameters                                                             //
  //                                                                         //
  // ======================================================================= //

  parameter int W  = 32
) (
  // ======================================================================= //
  //                                                                         //
  //  Launch Interface                                                       //
  //                                                                         //
  // ======================================================================= //

  //
  input                            l_in_pass_r,
  input        [W-1:0]             l_in_r,
  //
  output logic                     l_busy_r,

  // ======================================================================= //
  //                                                                         //
  //  Sync Interface                                                         //
  //                                                                         //
  // ======================================================================= //

  //
  input logic                      sync_c_ack_r,
  //
  output logic [W-1:0]             sync_l_out_r,
  output logic                     sync_l_out_valid_r,

  // ======================================================================= //
  //                                                                         //
  //  Misc.                                                                  //
  //                                                                         //
  // ======================================================================= //

  //
  input                            l_clk,
  input                            l_rst
);

  // ======================================================================= //
  //                                                                         //
  //  Wires                                                                  //
  //                                                                         //
  // ======================================================================= //

  typedef enum logic [0:0] {
      FSM_IDLE = 1'b0
    , FSM_BUSY = 1'b1
  } l_fsm_t;

  localparam int B_FSM_BUSY = 0;

  //
  l_fsm_t                          l_fsm_w;
  l_fsm_t                          l_fsm_r;
  //
  logic                            l_ack_r;
  //
  logic                            sync_l_ack_r;
  //
  logic                            sync_l_out_en;
  logic [W-1:0]                    sync_l_out_w;
  logic                            sync_l_out_valid_w;

  // ======================================================================= //
  //                                                                         //
  //  Combinatorial Logic                                                    //
  //                                                                         //
  // ======================================================================= //

  // ----------------------------------------------------------------------- //
  //
  always_comb
    begin : comb_PROC

      //
      sync_l_out_valid_w  = 'b0;
      sync_l_out_en       = 'b0;
      sync_l_out_w        = l_in_r;

      //
      l_fsm_w             = l_fsm_r;

      case (l_fsm_r)

        FSM_IDLE:
          if (l_in_pass_r) begin
            sync_l_out_en       = 'b1;
            sync_l_out_valid_w  = 'b1;
            //
            l_fsm_w             = FSM_BUSY;
          end

        FSM_BUSY:
          if (sync_l_ack_r)
            l_fsm_w             = FSM_IDLE;

      endcase // case (l_fsm_r)

      //
      l_busy_r  = l_fsm_r [B_FSM_BUSY];

    end // block: comb_PROC


  // ======================================================================= //
  //                                                                         //
  //  Instances                                                              //
  //                                                                         //
  // ======================================================================= //

  // ----------------------------------------------------------------------- //
  //
  always_ff @(posedge l_clk)
    if (sync_l_out_en)
      sync_l_out_r <= sync_l_out_w;

  // ----------------------------------------------------------------------- //
  //
  always_ff @(posedge l_clk)
    sync_l_out_valid_r <= sync_l_out_valid_w;

  // ----------------------------------------------------------------------- //
  //
  always_ff @(posedge l_clk)
    if (l_rst)
      l_fsm_r <= FSM_IDLE;
    else
      l_fsm_r <= l_fsm_w;

  // ----------------------------------------------------------------------- //
  //
  sync_ff u_sync_ff (
    //
      .q                 (sync_l_ack_r       )
    //
    , .d                 (sync_c_ack_r       )
    , .clk               (l_clk              )
    , .rst               (l_rst              )
  );

endmodule // mcp_formulation_l
