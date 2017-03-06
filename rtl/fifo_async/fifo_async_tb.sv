// -*-verilog-*-
//========================================================================== //
// Copyright (c) 2017, Stephen Henry
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

module fifo_async_tb (/*AUTOARG*/
  // Outputs
  pop_data, full_r, empty_r,
  // Inputs
  wrst, wclk, rrst, rclk, push_data, push, pop
  );
`define __OVERRIDE_CLK wclk
`include "libtb_tb_top_inc.vh"
  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input                 pop;                    // To u_fifo_async of fifo_async.v
  input                 push;                   // To u_fifo_async of fifo_async.v
  input [31:0]          push_data;              // To u_fifo_async of fifo_async.v
  input                 rclk;                   // To u_fifo_async of fifo_async.v
  input                 rrst;                   // To u_fifo_async of fifo_async.v
  input                 wclk;                   // To u_fifo_async of fifo_async.v
  input                 wrst;                   // To u_fifo_async of fifo_async.v
  // End of automatics
  /*AUTOOUTPUT*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output logic          empty_r;                // From u_fifo_async of fifo_async.v
  output logic          full_r;                 // From u_fifo_async of fifo_async.v
  output logic [31:0]   pop_data;               // From u_fifo_async of fifo_async.v
  // End of automatics
  fifo_async #(
               // Parameters
               .W                       (32),
               .N                       (32)
               /*AUTOINSTPARAM*/) u_fifo_async
 (/*AUTOINST*/
  // Outputs
  .pop_data                             (pop_data[31:0]),
  .empty_r                              (empty_r),
  .full_r                               (full_r),
  // Inputs
  .wclk                                 (wclk),
  .wrst                                 (wrst),
  .rclk                                 (rclk),
  .rrst                                 (rrst),
  .push                                 (push),
  .push_data                            (push_data[31:0]),
  .pop                                  (pop));
endmodule // fifo_async
