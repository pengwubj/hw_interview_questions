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
#include "Vfibonacci.h"

#define PORTS(__func)                           \
    __func(y, uint32_t)

struct FibonacciTb : libtb::TopLevel
{
    using UUT = Vfibonacci;
    SC_HAS_PROCESS(FibonacciTb);
    FibonacciTb(sc_core::sc_module_name mn = "t")
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
    bool run_test() {
        wait(1, SC_US);
        return true;
    }
    void m_checker() {
        const uint32_t expected = step_fibonacci();
        const uint32_t actual = y_;
        if (actual != expected) {
            std::stringstream ss;
            ss << "Mismatch: "
               << " actual=" << actual
               << " expected=" << expected
                ;
            LIBTB_REPORT_ERROR(ss.str());
        } else {
            std::stringstream ss;
            ss << "Validated " << actual;
            LIBTB_REPORT_DEBUG(ss.str());
        }
        next_trigger(clk().posedge_event());
    }
    int step_fibonacci() {
        const int ret = round_ ? f1_ : f0_;
        (round_ ? f1_ : f0_) = f0_ + f1_;
        round_ = !round_;
        return ret;
    }
    int f0_{1}, f1_{1};
    bool round_{false};
#define __declare_signal(__name, __type)        \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signal)
#undef __declare_signal
    UUT uut_;
};

int sc_main (int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<FibonacciTb>(argc, argv).start();
}
