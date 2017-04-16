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

// y = mx + c

module fused_multiply_add
(
   //======================================================================== //
   //                                                                         //
   // Misc.                                                                   //
   //                                                                         //
   //======================================================================== //

     input                                   clk
   , input                                   rst

   //======================================================================== //
   //                                                                         //
   // Cntrl                                                                   //
   //                                                                         //
   //======================================================================== //

   , input                                   cntrl_load
   , input        [31:0]                     cntrl_init

   //======================================================================== //
   //                                                                         //
   // Oprands                                                                 //
   //                                                                         //
   //======================================================================== //

   , input                                   pass
   , input        [15:0]                     m
   , input        [15:0]                     x
   , input        [15:0]                     c

   //======================================================================== //
   //                                                                         //
   // Result                                                                  //
   //                                                                         //
   //======================================================================== //

   , output logic                            y_valid_r
   , output logic [31:0]                     y_w
);

  // Result definition.
  //
  //   Y  += (M   x   X) + C
  //
  //  32b += (15b x 15b) + 15b
  //
  typedef logic [31:0] w_t;

  // Standard CSA compressor, swap out with STDCELL is applicable.
  //
  function logic [1:0] compress_3_to_2 (input [2:0] x);
    begin
      logic [1:0] r;
      r [0]  = (^x);
      r [1]  = (&x[1:0]) | (x[2] & (|x[1:0]));
      return r;
    end
  endfunction // compress_3_to_2

  function w_t  [1:0] compress_3_to_2_W (input w_t t,
                                         input w_t u,
                                         input w_t v);
    begin
      w_t a, b;
      for (int i = 0; i < $bits(w_t); i++) begin
        {a [i], b [i]} = compress_3_to_2 ({t[i], u[i], v[i]});
      end
      return {w_t'(a << 1), b};
    end
  endfunction // compress_3_to_2_W

  // ======================================================================== //
  //                                                                          //
  // Wires                                                                    //
  //                                                                          //
  // ======================================================================== //

  //
  w_t                         acc [8];
  w_t                         csa [18];
  //
  w_t                         csa_0_r;
  w_t                         csa_0_w;
  //
  w_t                         csa_1_r;
  w_t                         csa_1_w;
  //
  logic                       csa_en;
  //
  logic                       y_valid_w;
  //
  w_t                         x_w;
  w_t                         x_neg_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : booth_in_PROC

      //
      x_w     = w_t'(x);

      //
      x_neg_w  = '0 - w_t'(x);

    end

  // ------------------------------------------------------------------------ //
  //
  function w_t booth_recode_radix_4 (input [2:0] bth, int rshift);
    begin
      w_t r = '0;
      case (bth)
        3'b000: r = '0;
        3'b001: r = x_w;
        3'b010: r = x_w;
        3'b011: r = (x_w << 1);
        3'b100: r = (x_neg_w << 1);
        3'b101: r = x_neg_w;
        3'b110: r = x_neg_w;
        3'b111: r = '0;
      endcase // case (c)

      // Shift is performed as an Elaboration-time constant, therefore no
      // overhead is present in RTL.
      //
      return (r << rshift);
    end
  endfunction // booth_recode_radix_4

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : booth_PROC

      // Booth recoding network.
      //
      acc [0]         = booth_recode_radix_4 ({m [1:0], 1'b0}, 0);
      acc [1]         = booth_recode_radix_4 (m [3:1], 2);
      acc [2]         = booth_recode_radix_4 (m [5:3], 4);
      acc [3]         = booth_recode_radix_4 (m [7:5], 6);
      acc [4]         = booth_recode_radix_4 (m [9:7], 8);
      acc [5]         = booth_recode_radix_4 (m [11:9], 10);
      acc [6]         = booth_recode_radix_4 (m [13:11], 12);
      acc [7]         = booth_recode_radix_4 (m [15:13], 14);

    end // block: booth_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : csa_PROC

      //
      w_t c_w               = w_t'(c);

      // Booth CSA network
      //
      {csa [0], csa [1]}    = compress_3_to_2_W(acc [2], acc [1], acc [0]);
      {csa [2], csa [3]}    = compress_3_to_2_W(acc [5], acc [4], acc [3]);
      {csa [4], csa [5]}    = compress_3_to_2_W(csa [0], acc [7], acc [6]);
      {csa [6], csa [7]}    = compress_3_to_2_W(csa [3], csa [2], csa [1]);
      {csa [8], csa [9]}    = compress_3_to_2_W(csa [6], csa [5], csa [4]);
      {csa [10], csa [11]}  = compress_3_to_2_W(csa [9], csa [8], csa [7]);

      // Injection of increment (+C) (1)
      //
      {csa [12], csa [13]}  = compress_3_to_2_W(csa [11], csa [10], c_w);

      // Injection of accumulated results. (2)
      //
      {csa [14], csa [15]}  = compress_3_to_2_W(csa_0_r, csa_1_r, csa [12]);
      {csa [16], csa [17]}  = compress_3_to_2_W(csa [13], csa [14], csa [15]);

      // TODO place (1 and 2) at the top of the CSA as these are early
      // signals.

    end // block: csa_PROC

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : cntrl_PROC

      //
      csa_0_w    = cntrl_load ? cntrl_init : csa [16];
      csa_1_w    = cntrl_load ? '0 : csa [17];

      //
      csa_en     = pass | cntrl_load;

      //
      y_valid_w  = pass;

      //
      y_w        = csa_0_r + csa_1_r;

    end // block: cntrl_PROC

  // ======================================================================== //
  //                                                                          //
  // Flops                                                                    //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      y_valid_r <= '0;
    else
      y_valid_r <= y_valid_w;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (csa_en) begin
      csa_0_r <= csa_0_w;
      csa_1_r <= csa_1_w;
    end

endmodule // fused_multiply_add
