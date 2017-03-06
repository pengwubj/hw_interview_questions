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

module count_ones (input [7:0] A, output logic fail);


  localparam int RESULT_W  = $clog2(8) + 1;
  typedef logic [RESULT_W-1:0] result_t;

  logic [2:0]                  fail_v;

  result_t r0;
  always_comb
    begin : naive_PROC
      r0          = '0;
      for (int i = 0; i < 8; i++)
        r0 += ({RESULT_W{A[i]}} & 'b1);
    end

  function logic [2:0] LUT(input [3:0] in);
    case (in)
      4'b0000: return 0;
      4'b0001: return 1;
      4'b0010: return 1;
      4'b0011: return 2;
      4'b0100: return 1;
      4'b0101: return 2;
      4'b0110: return 2;
      4'b0111: return 3;
      4'b1000: return 1;
      4'b1001: return 2;
      4'b1010: return 2;
      4'b1011: return 3;
      4'b1100: return 2;
      4'b1101: return 3;
      4'b1110: return 3;
      4'b1111: return 4;
      default: return 0;
    endcase
  endfunction // LUT

  result_t r1;
  always_comb
    begin : lut4_PROC
      r1 = '0;
      for (int i = 0; i < 2; i++)
        r1 += LUT(A[(4 * i) +: 4]);
    end // block: lut4_PROC

  function [1:0] compress_3_to_2 (input [2:0] in);
    logic [1:0] r;
    r [0]  = (^in);
    r [1]  = (&in[1:0]) | (in[2] & (|in[1:0]));
    return r;
  endfunction

  result_t      r2;
  logic         unused_cout2;
  always_comb
    begin : csa_PROC
      logic [1:0] r0_0  = compress_3_to_2(A [2:0]);
      logic [1:0] r0_1  = compress_3_to_2(A [5:3]);
      logic [1:0] r0_2  = compress_3_to_2({1'b0, A [7:6]});

      logic [1:0] r1_0  = compress_3_to_2({r0_2 [0], r0_1[0], r0_0 [0]});
      logic [1:0] r1_1  = compress_3_to_2({r0_2 [1], r0_1[1], r0_0 [1]});

      {unused_cout2, r2} = {1'b0, r1_1, 1'b0} + {2'b0, r1_0};
    end // block: csa_PROC

  always_comb
    begin : combine_result_PROC

      result_t cnt  = result_t'($countones(A));

      fail_v        = '0;
      fail_v [0]    = (cnt != r0);
      fail_v [1]    = (cnt != r1);
      fail_v [2]    = (cnt != r2);

      fail          = (|fail_v);

    end // block: combine_result_PROC

endmodule // count_ones
