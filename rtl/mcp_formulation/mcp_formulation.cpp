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
#include "Vmcp_formulation.h"

#define PORTS(__func)                           \
    __func(l_in_pass_r, bool)                   \
    __func(l_in_r, WordT)                       \
    __func(l_busy_r, bool)                      \
    __func(c_out_pass_r, bool)                  \
    __func(c_out_r, WordT)

struct MCPFormulationTb : libtb::TopLevel
{
    using WordT = uint32_t;

    SC_HAS_PROCESS(MCPFormulationTb);
    MCPFormulationTb(sc_core::sc_module_name = "t")
        : uut_("uut")
        , rst2_("rst2_")
        , clk2_period_(0.5, sc_core::SC_NS)
        , clk2_("clk2", clk2_period_)
#define __construct_signals(__name, __type)     \
        , __name##_(#__name)
          PORTS(__construct_signals)
#undef __construct_signals
    {
        SC_METHOD(m_checker);
        sensitive << e_tb_sample();
        dont_initialize();

        SC_THREAD(t_reset);

        uut_.l_clk(clk());
        uut_.l_rst(rst());
        uut_.c_clk(clk2_);
        uut_.c_rst(rst2_);
#define __bind_signals(__name, __type)          \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals
    }

    bool run_test() {
        b_idle();
        wait(reset_done_);
        LIBTB_REPORT_INFO("Starting stimulus...");
        for (int i = 0; i < N_; i++)
            b_issue(libtb::random<WordT>());
        LIBTB_REPORT_INFO("Stimulus ends.");
        return false;
    }

    void b_idle() {
        l_in_pass_r_ = false;
        l_in_r_ = WordT();
    }

    void b_issue(const WordT & w) {
        do { t_wait_sync(); } while (l_busy_r_);

        l_in_pass_r_ = true;
        l_in_r_ = w;
        t_wait_posedge_clk();
        queue_.push_back(w);
        b_idle();
    }

    void t_reset () {
        rst2_ = false;
        t_wait_reset_done();

#define DO_WAIT_CLK2 wait(clk2_.posedge_event())
        DO_WAIT_CLK2;
        rst2_ = true;
        DO_WAIT_CLK2;
        rst2_ = false;
#undef DO_WAIT_CLK2

        reset_done_.notify();
    }

    void m_checker() {
        if (c_out_pass_r_) {
            if (queue_.size() == 0) {
                LIBTB_REPORT_ERROR("Unexpected retirement");
                return;
            }
            const WordT expected = queue_.front();
            queue_.pop_front();
            const WordT actual = c_out_r_;
            if (actual != expected) {
                std::stringstream ss;
                ss << "Mismatch:"
                   << " Expected=" << std::hex << expected
                   << " Actual=" << std::hex << actual;
                LIBTB_REPORT_ERROR(ss.str());
            }
        }
    }

    sc_core::sc_event reset_done_;
    sc_core::sc_time  clk2_period_;
    sc_core::sc_clock clk2_;
    sc_core::sc_signal<bool> rst2_;
    const int N_{10000};
    std::deque<WordT> queue_;
#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
    Vmcp_formulation uut_;
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<MCPFormulationTb>(argc, argv).start();
}
