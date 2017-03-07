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

module mcp_formulation_c #(

  // ======================================================================= //
  //                                                                         //
  //  Parameters                                                             //
  //                                                                         //
  // ======================================================================= //

  parameter int W  = 32
) (

  // ======================================================================= //
  //                                                                         //
  //  Sync Interface                                                         //
  //                                                                         //
  // ======================================================================= //

  //
  input [W-1:0]                         sync_l_out_r,
  input                                 sync_l_out_valid_r,
  //
  output logic                          sync_c_ack_r,

  // ======================================================================= //
  //                                                                         //
  //  Capture Interface                                                      //
  //                                                                         //
  // ======================================================================= //

  //
  output logic                          c_out_pass_r,
  output logic [W-1:0]                  c_out_r,

  // ======================================================================= //
  //                                                                         //
  //  Misc.                                                                  //
  //                                                                         //
  // ======================================================================= //

  //
  input                                 c_clk,
  input                                 c_rst

);

  typedef logic [W-1:0]                 w_t;

  // ======================================================================= //
  //                                                                         //
  //  Wires                                                                  //
  //                                                                         //
  // ======================================================================= //

  w_t                                   c_out_w;
  logic                                 c_out_pass_w;
  logic                                 c_out_en;
  //
  logic                                 sync_c_out_valid_r;
  logic                                 sync_c_out_valid_1_w;
  logic                                 sync_c_out_valid_1_r;
  //
  logic                                 c_sample;

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
      casez ({c_rst})
        1'b1:    sync_c_out_valid_1_w  = 1'b0;
        default: sync_c_out_valid_1_w  =     sync_c_out_valid_r
                                         & (~sync_c_out_valid_1_r)
                                       ;
      endcase // casez ({c_rst})

      //
      c_sample              = sync_c_out_valid_r & (~sync_c_out_valid_1_r);

      //
      sync_c_ack_r          = sync_c_out_valid_1_r;

      //
      casez ({c_rst, c_out_pass_r})
        2'b1_?:  c_out_pass_w  = 'b0;
        2'b0_1:  c_out_pass_w  = (~c_out_pass_r);
        default: c_out_pass_w  = c_sample;
      endcase

      //
      c_out_en      = c_sample;

      //
      c_out_w       = sync_l_out_r;

    end // block: comb_PROC

  // ======================================================================= //
  //                                                                         //
  //  Instances                                                              //
  //                                                                         //
  // ======================================================================= //

  // ----------------------------------------------------------------------- //
  //
  sync_ff u_sync_ff (
    //
      .q                 (sync_c_out_valid_r )
    //
    , .d                 (sync_l_out_valid_r )
    , .clk               (c_clk              )
    , .rst               (c_rst              )
  );

  // ----------------------------------------------------------------------- //
  //
  always_ff @(posedge c_clk)
    sync_c_out_valid_1_r <= sync_c_out_valid_r;

  // ----------------------------------------------------------------------- //
  //
  always_ff @(posedge c_clk)
    if (c_out_en)
      c_out_r <= c_out_w;

  // ----------------------------------------------------------------------- //
  //
  always_ff @(posedge c_clk)
    c_out_pass_r <= c_out_pass_w;

endmodule // mcp_formulation_
