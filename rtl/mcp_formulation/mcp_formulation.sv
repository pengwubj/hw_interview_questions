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

module mcp_formulation (/*AUTOARG*/
  // Outputs
  l_busy_r, c_out_r, c_out_pass_r,
  // Inputs
  l_rst, l_in_r, l_in_pass_r, l_clk, c_rst, c_clk
  );

  localparam int W = 32;

  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input logic           c_clk;                  // To u_mcp_formulation_c of mcp_formulation_c.v
  input logic           c_rst;                  // To u_mcp_formulation_c of mcp_formulation_c.v
  input logic           l_clk;                  // To u_mcp_formulation_l of mcp_formulation_l.v
  input logic           l_in_pass_r;            // To u_mcp_formulation_l of mcp_formulation_l.v
  input logic [W-1:0]   l_in_r;                 // To u_mcp_formulation_l of mcp_formulation_l.v
  input logic           l_rst;                  // To u_mcp_formulation_l of mcp_formulation_l.v
  // End of automatics
  /*AUTOOUTPUT*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output logic          c_out_pass_r;           // From u_mcp_formulation_c of mcp_formulation_c.v
  output logic [W-1:0]  c_out_r;                // From u_mcp_formulation_c of mcp_formulation_c.v
  output logic          l_busy_r;               // From u_mcp_formulation_l of mcp_formulation_l.v
  // End of automatics
  /*AUTOLOGIC*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  logic                 sync_c_ack_r;           // From u_mcp_formulation_c of mcp_formulation_c.v
  logic [W-1:0]         sync_l_out_r;           // From u_mcp_formulation_l of mcp_formulation_l.v
  logic                 sync_l_out_valid_r;     // From u_mcp_formulation_l of mcp_formulation_l.v
  // End of automatics

  // Launch clock
  mcp_formulation_l #(/*AUTOINSTPARAM*/
                      // Parameters
                      .W                (W)) u_mcp_formulation_l (/*AUTOINST*/
                                                                  // Outputs
                                                                  .l_busy_r             (l_busy_r),
                                                                  .sync_l_out_r         (sync_l_out_r[W-1:0]),
                                                                  .sync_l_out_valid_r   (sync_l_out_valid_r),
                                                                  // Inputs
                                                                  .l_in_pass_r          (l_in_pass_r),
                                                                  .l_in_r               (l_in_r[W-1:0]),
                                                                  .sync_c_ack_r         (sync_c_ack_r),
                                                                  .l_clk                (l_clk),
                                                                  .l_rst                (l_rst));

  // Capture clock
  mcp_formulation_c #(/*AUTOINSTPARAM*/
                      // Parameters
                      .W                (W)) u_mcp_formulation_c (/*AUTOINST*/
                                                                  // Outputs
                                                                  .sync_c_ack_r         (sync_c_ack_r),
                                                                  .c_out_pass_r         (c_out_pass_r),
                                                                  .c_out_r              (c_out_r[W-1:0]),
                                                                  // Inputs
                                                                  .sync_l_out_r         (sync_l_out_r[W-1:0]),
                                                                  .sync_l_out_valid_r   (sync_l_out_valid_r),
                                                                  .c_clk                (c_clk),
                                                                  .c_rst                (c_rst));

endmodule // mcp_formulation
