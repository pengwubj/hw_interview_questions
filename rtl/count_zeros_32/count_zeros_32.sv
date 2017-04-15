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

module count_zeros (

   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // In                                                                      //
   //                                                                         //
   //======================================================================== //

   , input                                   pass
   , input          [31:0]                   x

   //======================================================================== //
   //                                                                         //
   // Out                                                                     //
   //                                                                         //
   //======================================================================== //

   , output logic                            valid_r
   , output logic   [$clog2(32):0]           y
);

  typedef logic [31:0] w_t;
  typedef logic [3:0]  nibble_t;
  typedef logic [2:0]  nibble_cnt_t;
  typedef logic [$clog2(32):0] w_cnt_t;

  function nibble_cnt_t count_zeros (nibble_t x);
    begin
      nibble_cnt_t r = '0;
      case (x)
        4'b0000: r = 'd4;
        4'b0001: r = 'd3;
        4'b0010: r = 'd3;
        4'b0011: r = 'd2;
        4'b0100: r = 'd3;
        4'b0101: r = 'd2;
        4'b0110: r = 'd2;
        4'b0111: r = 'd1;
        4'b1000: r = 'd3;
        4'b1001: r = 'd2;
        4'b1010: r = 'd2;
        4'b1011: r = 'd1;
        4'b1100: r = 'd2;
        4'b1101: r = 'd1;
        4'b1110: r = 'd1;
        4'b1111: r = 'd0;
        default: r = 'd0;
      endcase // case (x)
      return r;
    end
  endfunction // count_zeros

  function logic [1:0] compress_3_to_2 (input [2:0] x);
    begin
      logic [1:0] r;
      r [0]  = (^x);
      r [1]  = (&x[1:0]) | (x[2] & (|x[1:0]));
      return r;
    end
  endfunction // compress_3_to_2

  function w_cnt_t [1:0] compress_3_to_2_N (input w_cnt_t x,
                                            input w_cnt_t y,
                                            input w_cnt_t z);
    begin
      w_cnt_t a, b;
      for (int i = 0; i < $bits(w_cnt_t); i++) begin
        {a [i], b [i]} = compress_3_to_2 ({x[i], y[i], z[i]});
      end
      return {w_cnt_t'(a << 1), b};
    end
  endfunction // compress_3_to_2_N

  nibble_cnt_t [7:0] nibble_cnt;
  
  always_comb
    begin : lookup_tables_PROC

      for (int i = 0; i < 8; i++)
        nibble_cnt [i] = count_zeros (x [i * 4 +: 4]);

    end // block: lookup_tables_PROC

  w_cnt_t csa_rnd_0 [8];
  w_cnt_t csa_rnd_1 [4];
  w_cnt_t csa_rnd_2 [5];
  w_cnt_t csa_rnd_3 [2];
  w_cnt_t csa_rnd_4 [4];
  
  always_comb
    begin : csa_PROC

      for (int i = 0; i < 8; i++)
        csa_rnd_0 [i] = w_cnt_t'(nibble_cnt [i]);

      { csa_rnd_1 [0], csa_rnd_1 [1] } = compress_3_to_2_N (csa_rnd_0 [0],
                                                            csa_rnd_0 [1],
                                                            csa_rnd_0 [2]);

      { csa_rnd_1 [2], csa_rnd_1 [3] } = compress_3_to_2_N (csa_rnd_0 [3],
                                                            csa_rnd_0 [4],
                                                            csa_rnd_0 [5]);
      
      { csa_rnd_2 [0], csa_rnd_2 [1] } = compress_3_to_2_N (csa_rnd_0 [6],
                                                            csa_rnd_0 [7],
                                                            csa_rnd_1 [0]);
      
      { csa_rnd_2 [3], csa_rnd_2 [4] } = compress_3_to_2_N (csa_rnd_1 [1],
                                                            csa_rnd_1 [2],
                                                            csa_rnd_1 [3]);
      
      { csa_rnd_3 [0], csa_rnd_3 [1] } = compress_3_to_2_N (csa_rnd_2 [0],
                                                            csa_rnd_2 [1],
                                                            csa_rnd_2 [2]);

      { csa_rnd_4 [0], csa_rnd_4 [1] } = compress_3_to_2_N (csa_rnd_2 [3],
                                                            csa_rnd_2 [4],
                                                            csa_rnd_3 [0]);
      
      { csa_rnd_4 [2], csa_rnd_4 [3] } = compress_3_to_2_N (csa_rnd_3 [1],
                                                            csa_rnd_4 [0],
                                                            csa_rnd_4 [1]);
    end // block: csa_PROC

  always_comb y = a_r + b_r;

  w_cnt_t a_r, b_r;
  
  always_ff @(posedge clk)
    if (pass) begin
      a_r <= csa_rnd_4 [2];
      b_r <= csa_rnd_4 [3];
    end

  always_ff @(posedge clk)
    if (rst)
      valid_r <= '0;
    else
      valid_r <= pass;
  
endmodule
