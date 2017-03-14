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
#include "Vvending_machine_dp.h"

#define PORTS(__func)                           \
    __func(client_nickel, bool)                 \
    __func(client_dime, bool)                   \
    __func(client_quarter, bool)                \
    __func(client_dispense, bool)               \
    __func(client_enough_r, bool)               \
    __func(serve_done, bool)                    \
    __func(serve_emit_irn_bru_r, bool)          \
    __func(change_done, bool)                   \
    __func(change_emit_dime_r, bool)

struct VendingMachineTb : libtb::TopLevel
{
    enum class CoinType {
        NICKEL, DIME, QUARTER
    };

    using UUT = Vvending_machine_dp;
    SC_HAS_PROCESS(VendingMachineTb);
    VendingMachineTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __construct_signals(__name, __type)     \
          , __name##_(#__name)
          PORTS(__construct_signals)
#undef __construct_signals
    {
        SC_THREAD(t_emit_serve_done);
        SC_THREAD(t_emit_change_done);
        SC_THREAD(t_dispense);

        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signals(__name, __type)          \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals
    }

    bool run_test() {
        LIBTB_REPORT_INFO("Stimulus starts...");
        test_0();
        LIBTB_REPORT_INFO("Stimulus ends.");
        return false;
    }

    void test_0() {
        LIBTB_REPORT_INFO("Test 0");
        issue_coin(CoinType::QUARTER);
        issue_coin(CoinType::QUARTER);

        t_wait_posedge_clk(100);
    }

    void issue_idle() {
        client_nickel_ = false;
        client_dime_ = false;
        client_quarter_ = false;
    }

    void issue_coin(CoinType c) {
        issue_idle();
        client_nickel_ = (c == CoinType::NICKEL);
        client_dime_ = (c == CoinType::DIME);
        client_quarter_ = (c == CoinType::QUARTER);
        t_wait_posedge_clk();
        issue_idle();
    }

    void reset_change_count() { change_count_ = 0; }

    void t_dispense() {

        const int DLY = 2;
        while (1) {
            client_dispense_ = false;
            wait(client_enough_r_.posedge_event());
            for (int i = 0; i < DLY; i++)
                t_wait_posedge_clk();
            client_dispense_ = true;
            t_wait_posedge_clk();
            client_dispense_ = false;
        }
    }

    void t_emit_change_done() {
        const int DLY = 4;
        while (1) {
            change_done_ = false;
            wait(change_emit_dime_r_.posedge_event());
            for (int i = 0; i < DLY; i++)
                t_wait_posedge_clk();
            change_count_++;
            change_done_ = true;
            t_wait_posedge_clk();
        }
    }

    void t_emit_serve_done() {
        const int DLY = 3;
        while (1) {
            serve_done_ = false;
            wait(serve_emit_irn_bru_r_.posedge_event());
            for (int i = 0; i < DLY; i++)
                t_wait_posedge_clk();
            serve_done_ = true;
            t_wait_posedge_clk();
        }
    }

    unsigned change_count_{0};
#define __declare_signals(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
    Vvending_machine_dp uut_;
};

int sc_main (int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<VendingMachineTb>(argc, argv).start();
}
