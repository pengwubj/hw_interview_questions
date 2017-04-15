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

#include <libtb.h>
#include <deque>
#include <sstream>
#include <bitset>

#include "Vzero_indices_fast.h"

#define ZERO_PROBABILITY 20

#define PORTS(__func)                           \
  __func(in_vector, sc_dt::sc_bv<128>)          \
  __func(in_start, bool)                        \
  __func(in_busy_r, bool)                       \
  __func(resp_valid_r, bool)                    \
  __func(resp_index_r, uint32_t)


struct ZeroIndicesFastTb : libtb::TopLevel
{
  using VectorT = sc_dt::sc_bv<128>;
  
  struct Stimulus
  {
    VectorT v;
    std::deque<uint32_t> p;
  };
  
  using RespQueueT = std::deque<Stimulus>;
  
  using UUT_t = Vzero_indices_fast;
  SC_HAS_PROCESS(ZeroIndicesFastTb);
  ZeroIndicesFastTb(sc_core::sc_module_name mn =  "t")
    : uut_("uut")
#define __construct_signal(__name, __type)      \
    , __name##_(#__name)
    PORTS(__construct_signal)
#undef __construct_signal
  {
    SC_METHOD(m_checker);
    dont_initialize();
    sensitive << e_tb_sample();
    
    uut_.clk(clk());
    uut_.rst(rst());
#define __bind_signal(__name, __type)           \
    uut_.__name(__name##_);
    PORTS(__bind_signal)
#undef __bind_signals
  }

  Stimulus construct_stimulus()
  {
    Stimulus s;
    for (int i = 0; i < 128; i++)
      s.v[i] = (libtb::random_integer_in_range(100) < (100 - ZERO_PROBABILITY));

    VectorT v = s.v;
    for (int i = 0; i < 128; i++) {
      if (!v[i])
        s.p.push_back(i);
    }
    return s;
  }

  void b_issue_in(const Stimulus & s)
  {
    std::stringstream ss;
    ss << "Issuing vector: " << s.v.to_string(SC_BIN);
    LIBTB_REPORT_DEBUG(ss.str());

    in_start_ = true;
    in_vector_ = s.v;
    t_wait_posedge_clk(1);
    in_start_ = false;
    wait(in_busy_r_.negedge_event());
  }

  bool run_test() {
    t_wait_reset_done();
    LIBTB_REPORT_INFO("Stimulus starts...");

    for (int i = 0; i < 10000; i++) {
      const Stimulus c = construct_stimulus();
      q_.push_back(c);
      b_issue_in(c);
    }
    
    LIBTB_REPORT_INFO("Stimulus ends..");
    return false;
  }

  void m_checker()
  {
    if (resp_valid_r_) {

    __retry:
      if (q_.size() == 0) {
        std::stringstream ss;
        ss << "Unexpected response";
        LIBTB_REPORT_FATAL(ss.str());
        return;
      }

      Stimulus & s = q_.front();
      if (s.p.size() == 0) {
        q_.pop_front();
        goto __retry;
      }

      const uint32_t expected = s.p.front(); s.p.pop_front();
      const uint32_t actual = resp_index_r_;

      if (expected != actual) {
        std::stringstream ss;
        ss << "Mismatch "
           << " Actual:" << std::dec << actual
           << " Expected:" << std::dec << expected
          ;
        LIBTB_REPORT_ERROR(ss.str());
      } else {
        std::stringstream ss;
        ss << "Validated index: " << std::dec << actual;
        LIBTB_REPORT_DEBUG(ss.str());
      }
    }
  }

  RespQueueT q_{};
#define __declare_signal(__name, __type)        \
  sc_core::sc_signal<__type> __name##_;
  PORTS(__declare_signal)
#undef __declare_signal
  UUT_t uut_;
};

int sc_main(int argc, char **argv)
{
  using namespace libtb;
  return LibTbSim<ZeroIndicesFastTb>(argc, argv).start();
}
