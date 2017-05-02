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
#include <sstream>
#include "Vusing_full_adders.h"
#define PORTS(__func)                           \
    __func(x, uint32_t)                         \
    __func(fail, bool)

struct UsingFullAddersTb : libtb::TopLevel
{
    using UUT = Vusing_full_adders;
    SC_HAS_PROCESS(UsingFullAddersTb);
    UsingFullAddersTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __construct_signal(__name, __type)      \
          , __name##_(#__name)
          PORTS(__construct_signal)
#undef __construct_signal
    {
        SC_METHOD(m_checker);
        dont_initialize();
        sensitive << e_reset_done();
        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signal(__name, __type)           \
        uut_.__name(__name##_);
        PORTS(__bind_signal)
#undef __bind_signals
    }
    void m_checker() {
        if (fail_) {
            std::stringstream ss;
            ss << "Mismatch detected x=" << x_;
            LIBTB_REPORT_ERROR(ss.str());
        }
        next_trigger(clk().posedge_event());
    }
    bool run_test() {
        x_ = 0;
        t_wait_reset_done();
        int n = 10000;
        while (n--)
        {
            x_ = libtb::random_integer_in_range(7, 0);
            t_wait_posedge_clk();
        }
        return false;
    }
#define __declare_signal(__name, __type)        \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signal)
#undef __declare_signal
    UUT uut_;
};

int sc_main (int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<UsingFullAddersTb>(argc, argv).start();
}
