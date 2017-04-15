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
#include "Vfused_multiply_add.h"

#define PORTS(__func)                           \
    __func(cntrl_load, bool)                    \
    __func(cntrl_init, uint32_t)                \
    __func(pass, bool)                          \
    __func(m, uint32_t)                         \
    __func(x, uint32_t)                         \
    __func(c, uint32_t)                         \
    __func(y_valid_r, bool)                     \
    __func(y_w, uint32_t)

struct Machine
{
    void init(uint32_t i) { y_ = i; }
    void apply(uint32_t m, uint32_t x, uint32_t c) {
        y_ += (m * x) + c;
    }

    uint32_t y_;
};

struct FMATb : libtb::TopLevel
{
  using UUT = Vfused_multiply_add;
  SC_HAS_PROCESS(FMATb);
  FMATb(sc_core::sc_module_name mn = "t")
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
    Machine mach;

    const uint32_t init = libtb::random<uint32_t>();
    cntrl_load_ = true;
    cntrl_init_ = init;
    t_wait_posedge_clk(1);
    mach.init(init);
    cntrl_load_ = false;
    for (int i = 0; i < 20; i++) {
        const uint32_t m = libtb::random_integer_in_range(100);
        const uint32_t x = libtb::random_integer_in_range(100);
        const uint32_t c = libtb::random_integer_in_range(100);

        pass_ = true;
        m_ = m;
        x_ = x;
        c_ = c;
        t_wait_posedge_clk();
        mach.apply(m, x, c);
        expected_.push_back(mach.y_);
    }
    pass_ = false;
    t_wait_posedge_clk(10);
    LIBTB_REPORT_INFO("Stimulus ends..");
    return false;
  }

  void m_checker()
  {
    if (y_valid_r_) {
      if (expected_.size() == 0) {
        std::stringstream ss;
        ss << "Unexpected result";
        LIBTB_REPORT_ERROR(ss.str());
        return;
      }

      const uint32_t actual = y_w_;
      const uint32_t expected = expected_.front(); expected_.pop_front();
      if (actual != expected) {
        std::stringstream ss;
        ss << "Mismatch detected: "
           << " Actual: " << actual
           << " Expected: " << expected;
        LIBTB_REPORT_ERROR(ss.str());
      } else {
        std::stringstream ss;
        ss << "Validated result=" << expected;
        LIBTB_REPORT_DEBUG(ss.str());
      }
    }
  }
  std::deque<uint32_t> expected_;
#define __declare_signal(__name, __type)        \
  sc_core::sc_signal<__type> __name##_;
  PORTS(__declare_signal)
#undef __declare_signal
  UUT uut_;
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<FMATb>(argc, argv).start();
}
