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

module gates_from_MUX2X1 ( input a, input b, output logic fail );

  logic [3:0] fail_v;

  logic       y_inv_expected;
  logic       y_and_expected;
  logic       y_or_expected;
  logic       y_xor_expected;

  logic       y_inv_actual;
  logic       y_and_actual;
  logic       y_or_actual;
  logic       y_xor_actual;

`define MUX2X1(__a, __b, __sel) ((~__sel) & __a | (__sel & __b))

  always_comb
    begin : gates_PROC

      fail_v          = '0;

      // inv: Y = (!A)
      y_inv_expected  = (~a);
      y_inv_actual    = `MUX2X1(1, 0, a);
      fail_v[0]       = (y_inv_expected ^ y_inv_actual);

      // and: Y = AB
      y_and_expected  = (a & b);
      y_and_actual    = `MUX2X1(0, a, b);
      fail_v[1]       = (y_and_expected ^ y_and_actual);

      // or: Y = A + B
      y_or_expected   = (a | b);
      y_or_actual     = `MUX2X1(a, 1, b);
      fail_v[2]       = (y_or_expected ^ y_or_actual);

      // xor: Y = A!B + !AB
      y_xor_expected  = (a ^ b);

      begin : xor_BLOCK
        logic a_inv     = `MUX2X1(1, 0, a);
        logic b_inv     = `MUX2X1(1, 0, b);

        logic a_nb_and  = `MUX2X1(0, a, b_inv);
        logic na_b_and  = `MUX2X1(0, b, a_inv);

        y_xor_actual    = `MUX2X1(na_b_and, 1, a_nb_and);
      end
      fail_v[3]       = (y_xor_expected ^ y_xor_actual);

    end // block: gates_PROC
`undef MUX2X1

  always_comb fail = (|fail_v);

endmodule // gates_from_MUX2X1
