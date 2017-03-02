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
#include <sstream>
#include "delay_pipe.h"
#include "Vlatency.h"

#define PORTS(__func)                           \
    __func(issue, bool)                         \
    __func(clear, bool)                         \
    __func(retire, bool)                        \
    __func(issue_cnt_r, WordT)                  \
    __func(aggregate_cnt_r, WordT)

using WordT = uint32_t;

class LatencyTb : libtb::TopLevel
{

public:
    SC_HAS_PROCESS(LatencyTb);
    LatencyTb(sc_core::sc_module_name mn = "t")
        : uut_("uut") {
        wave_on("foo.vcd", uut_);
        //
        in_flight_pipe_.clk(clk());
        in_flight_pipe_.in(issue_);
        in_flight_pipe_.out(retire_);
        //
        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signals(__name, __type)          \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals
    }

private:

    bool run_test()
    {
        t_wait_reset_done();
        for (int round = 0; round < 100; round++)
        {
            bool fail = false;

            in_flight_pipe_.clear();
            hw_clear();
            const int expected_delay =
                libtb::random_integer_in_range(100, 1);
            in_flight_pipe_.set_delay(expected_delay);
            run_round();

            t_wait_posedge_clk(100);

            t_wait_sync();
            if (issue_cnt_r_ != TRANSACTION_COUNT) {
                fail = true;

                std::stringstream ss;
                ss << "Invalid transaction count"
                   << " Expected=" << TRANSACTION_COUNT
                   << " Actual=" << issue_cnt_r_;
                LIBTB_REPORT_ERROR(ss.str());
            }
            const int actual_delay =
                (aggregate_cnt_r_ / issue_cnt_r_);
            if (in_flight_pipe_.get_delay() != actual_delay) {
                fail = true;

                std::stringstream ss;
                ss << "Computed delay is incorrect"
                   << " Expected=" << in_flight_pipe_.get_delay()
                   << " Actual=" << actual_delay;
                ss << " aggregate_cnt_r_=" << aggregate_cnt_r_
                   << " issue_cnt_r_=" << issue_cnt_r_;
                LIBTB_REPORT_ERROR(ss.str());
            }
            if (!fail) {
                std::stringstream ss;
                ss << "PASS Delay validated=" << expected_delay;
                LIBTB_REPORT_DEBUG(ss.str());
            }
        }
        return false;
    }

    void run_round()
    {
        for (int i = 0; i < TRANSACTION_COUNT; i++) {
            issue_ = true;
            t_wait_posedge_clk();
        }
        issue_ = false;
    }

    void hw_clear()
    {
        clear_ = true;
        t_wait_posedge_clk();
        clear_ = false;
    }

    DelayPipe<bool> in_flight_pipe_;

    const int TRANSACTION_COUNT{10};
#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
    Vlatency uut_;
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;

    LatencyTb t;
    LibTbContext::init(argc, argv);
    return LibTbContext::start();
}
