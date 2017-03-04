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

module spsram #(parameter int W = 32, parameter int N = 128)
(
    input                               clk
  , input                               csn
  , input                               wen
  , input                               oen
  , input         [$clog2(N)-1:0]       a
  , input         [W-1:0]               di
  //
  , output logic  [W-1:0]               dout
);

  typedef logic [W-1:0]                 w_t;
  typedef w_t [N-1:0]         mem_t;
  mem_t mem_r;

  logic                                 do_write;
  logic                                 do_read;

  always_comb do_write  = (~csn) & (~wen);
  always_comb do_read   = (~csn) & (~oen) & wen;

  always_ff @(posedge clk)
    if (do_write)
      mem_r [a] <= di;

  always_ff @(posedge clk)
    dout <= do_read ? mem_r [a] : 'x;

endmodule // spsram
