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

#include <libtb.h>
#include <deque>
#include "Vdiv_by_3.h"

#define PORTS(__func)                           \
  __func(pass, bool)                            \
  __func(x, uint32_t)                           \
  __func(busy_r, bool)                          \
  __func(valid_r, bool)                         \
  __func(y_r, uint32_t)

struct DivBy3Tb : libtb::TopLevel
{
  struct Result {
      uint32_t d, result;
  };

  using UUT = Vdiv_by_3;
  SC_HAS_PROCESS(DivBy3Tb);
  DivBy3Tb(sc_core::sc_module_name mn = "t")
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
  bool run_test()
  {
    t_wait_reset_done();
    LIBTB_REPORT_INFO("Stimulus starts...");
    int n = 10000;
    while (n--) {
        const uint32_t x = libtb::random_integer_in_range((1 << 15) - 1);
        pass_ = true;
        x_ = x;
        t_wait_posedge_clk(1);
        pass_ = false;
        expected_.push_back(Result{x, x / 3});

        // On each round, simply wait until the computation is complete to avoid
        // exposing the TB to any flow-control.
        //
        t_wait_posedge_clk(10);
    }
    t_wait_posedge_clk(10);
    LIBTB_REPORT_INFO("Stimulus ends..");
    return false;
  }

  void m_checker()
  {
    if (valid_r_) {
      if (expected_.size() == 0) {
        std::stringstream ss;
        ss << "Unexpected result";
        LIBTB_REPORT_ERROR(ss.str());
        return;
      }

      const uint32_t actual = y_r_;
      const Result expected = expected_.front(); expected_.pop_front();
      if (actual != expected.result) {
        std::stringstream ss;
        ss << "Mismatch detected: "
           << " Oprand: " << expected.d
           << " Actual: " << actual
           << " Expected: " << expected.result;
        LIBTB_REPORT_ERROR(ss.str());
      } else {
        std::stringstream ss;
        ss << "Validated oprand=" << expected.d << " " << actual;
        LIBTB_REPORT_DEBUG(ss.str());
      }
    }
  }
  std::deque<Result> expected_;
#define __declare_signal(__name, __type)        \
  sc_core::sc_signal<__type> __name##_;
  PORTS(__declare_signal)
#undef __declare_signal
  UUT uut_;
};


int sc_main(int argc, char **argv)
{
  using namespace libtb;
  return LibTbSim<DivBy3Tb>(argc, argv).start();
}
