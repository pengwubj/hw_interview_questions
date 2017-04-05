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

module multiply_by_21 #(parameter int W = 32) (input [W-1:0] a,
                                               output logic fail);

  localparam int X = 21; // 10101
  localparam int Y_W = W + $clog2(X) + 1;
  typedef logic [Y_W-1:0] y_t;

  y_t y_expected;
  y_t y_actual;
  
  always_comb
    begin : compute_y_PROC

      //
      y_expected = a * X;

      // Infer an adder for the sparse bits set to 1 in the
      // multiplication factor. Note, since the predicate is an
      // elaboration-time constant, the inference carried out by a
      // synthesis tool should be static and minimal.
      //
      y_actual = '0;
      for (int i = 0; i < $bits(X); i++)
        if (X[i])
          y_actual += y_t'(a) << i;

      // This is structurally equivalent to:
      // y_actual += y_t'(a);
      // y_actual += y_t'(a) << 2;
      // y_actual += y_t'(a) << 4;

      // NOTE: y_t'(a) << 4 != y_t'(a << 4).
      // The RHS is wrong because the extension should take place
      // before the shift operation (not after). The RHS results in
      // truncation of the output result.

      fail = (y_actual != y_expected);

    end // block: compute_y_PROC

endmodule // multiply_by_21

  
