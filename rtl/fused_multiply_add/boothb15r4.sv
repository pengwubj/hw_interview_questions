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

module boothb15r4 (input [15:0] a,
                   input [15:0]        b,
                   output logic [31:0] y_1,
                   output logic [31:0] y_2);

  typedef logic [31:0] w_t;

  w_t a_w, b_w;
  always_comb
    begin
      a_w = w_t'(a);
      b_w = w_t'(b);
    end 

  function logic [1:0] compress_3_to_2 (input [2:0] x);
    begin
      logic [1:0] r;
      r [0]  = (^x);
      r [1]  = (&x[1:0]) | (x[2] & (|x[1:0]));
      return r;
    end
  endfunction // compress_3_to_2

  function w_t  [1:0] compress_3_to_2_W (input w_t x,
                                         input w_t y,
                                         input w_t z);
    begin
      w_t a, b;
      for (int i = 0; i < $bits(w_t); i++) begin
        {a [i], b [i]} = compress_3_to_2 ({x[i], y[i], z[i]});
      end
      return {w_t'(a << 1), b};
    end
  endfunction // compress_3_to_2_W

  function w_t inc_by_1 (w_t x);
    return x + 'b1;
  endfunction // inc_by_1

  w_t a_plus_1;
  always_comb a_plus_1 = inc_by_1(a_w);
    
  function w_t booth_recode_radix_4 (input [2:0] c);
    begin
      w_t r = '0;
      case (c)
        3'b000: r = 'b0;
        3'b001: r = a_w;
        3'b010: r = a_w;
        3'b011: r = w_t'(a_w << 1);
        3'b100: r = w_t'(a_plus_1 << 1);
        3'b101: r = a_plus_1;
        3'b110: r = a_plus_1;
        3'b111: r = 'b0;
      endcase // case (c)
      return r;
    end
  endfunction // booth_recode_radix_4

  function w_t rsh (w_t x, int i);
    return w_t'(x << i);
  endfunction // rsh

  w_t acc [8];
  
  always_comb
    begin : booth_PROC
      acc [0] = rsh(booth_recode_radix_4 ({b [1:0], 1'b0}), 0);
      acc [1] = rsh(booth_recode_radix_4 (b [3:1]), 2);
      acc [2] = rsh(booth_recode_radix_4 (b [5:3]), 4);
      acc [3] = rsh(booth_recode_radix_4 (b [7:5]), 6);
      acc [4] = rsh(booth_recode_radix_4 (b [9:7]), 8);
      acc [5] = rsh(booth_recode_radix_4 (b [11:9]), 10);
      acc [6] = rsh(booth_recode_radix_4 (b [13:11]), 12);
      acc [7] = rsh(booth_recode_radix_4 (b [15:13]), 14);
    end // block: booth_PROC

  w_t csa [12];

  always_comb
    begin : csa_PROC
      {csa [0], csa [1]} = compress_3_to_2_W(acc [2], acc [1], acc [0]);
      {csa [2], csa [3]} = compress_3_to_2_W(acc [5], acc [4], acc [3]);
      {csa [4], csa [5]} = compress_3_to_2_W(csa [0], acc [7], acc [6]);
      {csa [6], csa [7]} = compress_3_to_2_W(csa [3], csa [2], csa [1]);
      {csa [8], csa [9]} = compress_3_to_2_W(csa [6], csa [5], csa [4]);
      {csa [10], csa [11]} = compress_3_to_2_W(csa [9], csa [8], csa [7]);
    end // block: csa_PROC

  always_comb
    begin : y_PROC
      y_1 = csa [10];
      y_2 = csa [11];
    end // block: y_PROC
  
endmodule // boothb15r4
  
