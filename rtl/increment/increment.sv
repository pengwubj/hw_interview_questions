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

module increment #(parameter int W = 32) (input [W-1:0] A, output logic fail);

  typedef logic [W-1:0] w_t;

  //
  w_t                   y_naive;
  logic                 unused_co;
  //
  w_t                   y_optimal;

  // Function to compute a 1hot mask denoting the position of the right-most 0
  // in an input vector.
  //
  function w_t ffs0 (input w_t x);
    w_t ret     = '0;
    for (int i = W - 1; i >= 0; i--)
      if (x[i] == 0)
        ret  = (1 << i);
    return ret;
  endfunction // ffs0

  // Function to derive the inclusive lsb-oriented mask from an input 1hot mask.
  //
  function w_t inclusive_mask(input w_t x);
    w_t ret = '0;
    logic bit_set  = '0;
    for (int i = W - 1; i >= 0; i--) begin
      bit_set |= x[i];
      ret[i] = bit_set;
    end
    return ret;
  endfunction

  //
  always_comb
    {unused_co, y_naive}  = (A + 'b1);

  //
  always_comb
    begin : increment_PROC

      w_t first_0_1hot_vec  = ffs0(A);

      w_t first_0_and_mask  = inclusive_mask(first_0_1hot_vec);

      y_optimal             = (A ^ first_0_and_mask);

    end // block: increment_PROC

  //
  always_comb fail = (y_naive != y_optimal);

endmodule // increment
