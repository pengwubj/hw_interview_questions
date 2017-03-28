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

`define HAS_DETFF 1

module clk_div_by_3 (input clk, input rst, output logic clk_div_3);


  logic [1:0] cnt_pos_r, cnt_pos_w;
  logic [1:0] cnt_neg_r, cnt_neg_w;


  logic       cnt_pos_out_r;
  logic       cnt_neg_out_r;
`ifndef HAS_DETFF
  logic       cnt_pos_out_w;
  logic       cnt_neg_out_w;
`endif

  always_comb
    begin
      cnt_pos_w = (cnt_pos_r == 'd2) ? 'b0 : cnt_pos_r + 'b1;
      cnt_neg_w = (cnt_neg_r == 'd2) ? 'b0 : cnt_neg_r + 'b1;
    end

`ifdef HAS_DETFF
  // On FPGA flows, attempt to avoid glitches by flopping all combinatorial
  // logic in the path before clock generation. The presence of the OR is
  // undersirable but necessary.
  //
  always_comb clk_div_3 = cnt_pos_out_r | cnt_neg_out_r;
`else
  // Flop output using Double-Edge Triggered FF to eliminate any possibility of
  // glitching on generated clock. NOTE: DETFF are unsupported on FPGA flows.
  //
  detff u_detff (.q(clk_div_3), .d_p(cnt_pos_w), .d_n(cnt_pos_n), .clk(clk));
`endif

`ifdef HAS_DETFF
  always_ff @(posedge clk)
    cnt_pos_out_r <= (cnt_pos_w == '0);
`endif

`ifdef HAS_DETFF
  always_ff @(negedge clk)
    cnt_neg_out_r <= (cnt_neg_w == '0);
`endif

  always_ff @(posedge clk or negedge rst)
    if (rst)
      cnt_pos_r <= '0;
    else
      cnt_pos_r <= cnt_pos_w;

  always_ff @(negedge clk or negedge rst)
    if (rst)
      cnt_neg_r <= 'd2;
    else
      cnt_neg_r <= cnt_neg_w;

endmodule // clk_div_by_3
