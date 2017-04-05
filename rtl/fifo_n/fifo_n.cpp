//========================================================================== //
// Copyright (c) 2016-17, Stephen Henry
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
#include "Vfifo_n.h"

#define PORTS(__func)                           \
  __func(push, bool)                            \
  __func(push_vq, VqEncT)                       \
  __func(push_data, WordT)                      \
  __func(pop, bool)                             \
  __func(pop_vq, VqEncT)                        \
  __func(pop_data_valid_r, bool)                \
  __func(pop_data_vq_r, VqEncT)                 \
  __func(pop_data_w, WordT)                     \
  __func(empty_r, VqT)                          \
  __func(full_r, VqT)

constexpr int OPT_VQ_N = 8;
constexpr int OPT_N = 8;

struct FifoNTb : libtb::TopLevel
{
  using UUT = Vfifo_n;

  using VqEncT = uint32_t;
  using WordT = uint32_t;
  using VqT = uint32_t;
  
  SC_HAS_PROCESS(FifoNTb);
  FifoNTb(sc_core::sc_module_name mn = "t")
    : uut_("uut")
#define __construct_signals(__name, __type)     \
    , __name##_(#__name)
    PORTS(__construct_signals)
#undef __construct_signals
  {
    SC_METHOD(m_checker);
    dont_initialize();
    sensitive << e_tb_sample();

    SC_THREAD(t_popper);
              
    uut_.clk(clk());
    uut_.rst(rst());
#define __bind_signals(__name, __type)          \
    uut_.__name(__name##_);
    PORTS(__bind_signals)
#undef __bind_signals
  }

  void b_push_idle()
  {
    push_ = false;
    push_vq_ = VqT();
    push_data_ = WordT();
  }

  void b_push(VqT vq)
  {
    const WordT w = libtb::random<WordT>();
    push_ = true;
    push_vq_ = vq;
    push_data_ = w;
    t_wait_posedge_clk();
    fifo_n_[vq].push_back(w);
    b_push_idle();
  }

  bool run_test()
  {
    LIBTB_REPORT_INFO("Stimulus starts");
    int n = N;
    while (n--) {
      const int vq = libtb::random_integer_in_range(OPT_VQ_N - 1);

      t_wait_sync();
      if (fifo_n_[vq].size() == OPT_N) {
        LIBTB_ASSERT_ERROR(full_r_ | (1 << vq));
        t_wait_posedge_clk();
      }
      else
        b_push(vq);
    }
    
    LIBTB_REPORT_INFO("Stimulus ends");
    return true;
  }

  void b_pop_idle()
  {
    pop_ = false;
    pop_vq_ = VqT(0);
  }

  void b_pop (VqT vq)
  {
    pop_ = true;
    pop_vq_ = vq;
    const WordT w = fifo_n_[vq].front();
    fifo_n_[vq].pop_front();
    expectation_.push_back(w);
    t_wait_posedge_clk(1);
    b_pop_idle();
  }

  void t_popper()
  {
    t_wait_reset_done();

    LIBTB_REPORT_DEBUG("Popper thread begins.");
    
    while (true) {
      t_wait_sync();
      const int vq = libtb::random_integer_in_range(OPT_VQ_N-1);
      if (fifo_n_[vq].size() > 0) {
        LIBTB_ASSERT_ERROR(~(empty_r_ | (1 << vq)));
        b_pop(vq);
      } else
        t_wait_posedge_clk(1);
    }
  }

  void m_checker()
  {

    // Check output
    if (pop_data_valid_r_) {

      if (expectation_.size() == 0) {
        LIBTB_REPORT_ERROR("Unexpected completion.");
        return ;
      }

      const WordT expected = expectation_.front();
      expectation_.pop_front();
      const WordT actual = pop_data_w_;
      if (expected != actual) {
        std::stringstream ss;
        ss << "Mismatch detected";
        LIBTB_REPORT_ERROR(ss.str());
      }
    }
  }

  const int N{10000};
  std::deque<WordT> fifo_n_[OPT_VQ_N];
  std::deque<WordT> expectation_;
#define __declare_signals(__name, __type)       \
  sc_core::sc_signal<__type> __name##_;
  PORTS(__declare_signals)
#undef __declare_signals
  UUT uut_;
};

int sc_main (int argc, char **argv)
{
  using namespace libtb;
  return LibTbSim<FifoNTb>(argc, argv).start();
}
