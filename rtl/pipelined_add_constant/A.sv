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


module A#(parameter int W = 32)
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
   // Oprands                                                                 //
   //                                                                         //
   //======================================================================== //

   , input          [W-1:0]                 a_init
   , input          [W-1:0]                 i
   //
   , input                                  init
 
   //======================================================================== //
   //                                                                         //
   // Result                                                                  //
   //                                                                         //
   //======================================================================== //

   , output logic   [W-1:0]                  y_w
);

  typedef logic [W-1:0]                      w_t;
  w_t A_r, A_w, I_r;

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      //
      A_w                 = A_r + w_t'(I_r);

      //
      y_w                 = A_w;

    end

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (init)
      I_r <= i;

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      A_r <= '0;
    else
      A_r <= init ? a_init : A_w;

endmodule // A

