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

module latency #(parameter int W = 32)
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
   // Control                                                                 //
   //                                                                         //
   //======================================================================== //

   , input                                   issue
   , input                                   clear
   //
   , input                                   retire

   //======================================================================== //
   //                                                                         //
   // State                                                                   //
   //                                                                         //
   //======================================================================== //

   , output logic   [W-1:0]                  issue_cnt_r
   , output logic   [W-1:0]                  aggregate_cnt_r
);

  typedef logic [W-1:0]                 w_t;

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  w_t                                   issue_cnt_r;
  w_t                                   issue_cnt_w;
  logic                                 issue_cnt_en;
  //
  w_t                                   pending_cnt_r;
  w_t                                   pending_cnt_w;
  logic                                 pending_cnt_en;
  //
  w_t                                   aggregate_cnt_r;
  w_t                                   aggregate_cnt_w;
  logic                                 aggregate_cnt_en;
  //
  logic                                 in_flight;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : cnt_PROC

      //
      casez ({rst, clear, issue, retire})
        4'b1_?_?_?,
        4'b0_1_?_?: pending_cnt_w  = 'b0;
        4'b0_0_1_0: pending_cnt_w  = pending_cnt_r + 'b1;
        4'b0_0_0_1: pending_cnt_w  = pending_cnt_r - 'b1;
        default:    pending_cnt_w  = pending_cnt_r;
      endcase // casez ({rst, clear, issue, retire})

      //
      pending_cnt_en  = (rst | clear | issue | retire);

      //
      in_flight       = (|pending_cnt_w);

      //
      casez ({rst, clear, issue})
        3'b1_?_?,
        3'b0_1_?: issue_cnt_w  = 'b0;
        3'b0_0_1: issue_cnt_w  = issue_cnt_r + 'b1;
        default:  issue_cnt_w  = issue_cnt_r;
      endcase // casez ({rst, clear, issue})

      //
      issue_cnt_en  = (rst | clear | issue);

      //
      casez ({rst, clear})
        2'b1_?,
        2'b0_1:  aggregate_cnt_w  = 'b0;
        default: aggregate_cnt_w  = aggregate_cnt_r + pending_cnt_w;
      endcase // casez ({rst, clear})

      //
      aggregate_cnt_en = (rst | clear | in_flight);

    end // block: cnt_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (issue_cnt_en)
      issue_cnt_r <= issue_cnt_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (aggregate_cnt_en)
      aggregate_cnt_r <= aggregate_cnt_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (pending_cnt_en)
      pending_cnt_r <= pending_cnt_w;

endmodule // latency
