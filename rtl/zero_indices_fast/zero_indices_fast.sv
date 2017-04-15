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

`define HAS_FINAL

module zero_indices_fast #(parameter int W = 128) (

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

   , input          [W-1:0]                  in_vector
   , input                                   in_start
   //
   , output                                  in_busy_r

   //======================================================================== //
   //                                                                         //
   // Reponse                                                                 //
   //                                                                         //
   //======================================================================== //

   , output logic                            resp_valid_r
   , output logic   [6:0]                    resp_index_r
);
  localparam int V = 16;
  localparam int X = (W / V);

  typedef logic [V-1:0] v_t;
  typedef struct packed {
    v_t [X-1:0] v;
  } w_t;
  typedef logic [X-1:0] x_t;
  typedef logic [$clog2(X)-1:0] x_e_t;
  typedef logic [$clog2(V)-1:0] v_e_t;
  typedef struct packed {
    x_e_t  x;
    v_e_t  v;
  } resp_index_t;

  typedef struct packed {
    v_e_t [X-1:0] v;
  } slow_resp_index_t;

  w_t                 vector_w;
  //
  x_t                 has_zeros_n_w;
  //
  logic               resp_valid_w;
  resp_index_t        resp_index_w;
  //
  logic               select_resp_valid;
  x_e_t               select_resp_index;
  //
  logic               select_en;
  logic               select_done_r;
  //
  x_t                 slow_en;
  x_t                 slow_done_r;
`ifdef HAS_FINAL
  x_t                 slow_final_r;
`endif
  //
  x_t                 slow_resp_valid_r;
  slow_resp_index_t   slow_resp_index_r;
  //
  logic               in_busy_w;

  // ======================================================================== //
  //                                                                          //
  // Combinatorial Logic                                                      //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : resp_PROC

      resp_valid_w = '0;
      for (int i = 0; i < X; i++)
        resp_valid_w |= select_resp_valid & slow_resp_valid_r [select_resp_index];

      resp_index_w = '0;
      resp_index_w.x = select_resp_index;
      resp_index_w.v = slow_resp_index_r.v [select_resp_index];

    end // block: resp_PROC
  
  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : select_PROC

      //
`ifdef HAS_FINAL
      select_en = in_start | (select_resp_valid & slow_final_r [select_resp_index]);
`else
      select_en = in_start | (select_resp_valid & slow_done_r [select_resp_index]);
`endif
    end
  
  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : slow_PROC

      //
      for (int i =0 ; i < X; i++)
        slow_en [i] = select_resp_valid & (select_resp_index == x_e_t'(i));
            
    end
  
  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin

      //
      vector_w = in_vector;

      //
      for (int i = 0; i < X; i++)
        has_zeros_n_w [i] = ~(in_vector [i * V +: V] != '1);

    end
  
  // ------------------------------------------------------------------------ //
  //
  always_comb
    begin : in_busy_PROC

      //
      in_busy_w = in_start | in_busy_r & (~select_done_r);

    end

  // ======================================================================== //
  //                                                                          //
  // Sequential Logic                                                         //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      resp_valid_r <= '0;
    else
      resp_valid_r <= resp_valid_w;
  
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (resp_valid_w)
      resp_index_r <= resp_index_w;
 
  // ------------------------------------------------------------------------ //
  //
  always_ff @(posedge clk)
    if (rst)
      in_busy_r <= '0;
    else
      in_busy_r <= in_busy_w;

  // ======================================================================== //
  //                                                                          //
  // Instances                                                                //
  //                                                                          //
  // ======================================================================== //

  // ------------------------------------------------------------------------ //
  //
  zero_indices_slow #(.W(X)) u_zero_indices_select (
    //
      .clk                    (clk                )
    , .rst                    (rst                )
    //
    , .in_vector              (has_zeros_n_w      )
    , .in_load                (in_start           )
    //
    , .en                     (select_en          )
    , .done_r                 (select_done_r      )
`ifdef HAS_FINAL
    , .final_r                ()
`endif
    //
    , .resp_valid             (select_resp_valid  )
    , .resp_index             (select_resp_index  )
  );
  
  // ------------------------------------------------------------------------ //
  //
  generate for (genvar g = 0; g < X; g++) begin
  
  zero_indices_slow #(.W(V)) u_zero_indices_slow (
    //
      .clk                    (clk                )
    , .rst                    (rst                )
    //
    , .in_vector              (vector_w.v [g]     )
    , .in_load                (in_start           )
    //
    , .en                     (slow_en [g]        )
    , .done_r                 (slow_done_r [g]    )
`ifdef HAS_FINAL
    , .final_r                (slow_final_r [g]   )
`endif
    //
    , .resp_valid             (slow_resp_valid_r [g])
    , .resp_index             (slow_resp_index_r.v [g])
  );

  end endgenerate

endmodule // zero_indices_slow
