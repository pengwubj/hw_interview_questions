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
#include <vector>
#include <algorithm>
#include <sstream>
#include "Vmissing_duplicated_word.h"

#define PORTS(__func)                           \
    __func(bool, state_upt)                     \
    __func(IdT, state_id)                       \
    __func(DatT, state_dat)                     \
    __func(bool, cntrl_start)                   \
    __func(bool, cntrl_busy_r)                  \
    __func(DatT, cntrl_dat_r)

constexpr int OPT_W = 5;
constexpr int OPT_N = 17;

struct MissingDuplicatedWordTb : libtb::TopLevel
{
    using UUT = Vmissing_duplicated_word;
    using IdT = uint32_t;
    using DatT = uint32_t;

    SC_HAS_PROCESS(MissingDuplicatedWordTb);
    MissingDuplicatedWordTb(sc_core::sc_module_name mn = "t")
        : libtb::TopLevel(mn)
        , uut_("uut")
#define __construct_signals(__type, __name)     \
        , __name##_(#__name)
        PORTS(__construct_signals)
#undef __construct_signals
    {
        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signals(__type, __name)          \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals
    }

    void b_configure_state()
    {
        std::vector<DatT> d;
        non_duplicated_ =
            libtb::random_integer_in_range((1 << OPT_W) - 1);
        {
            std::stringstream ss;
            ss << "Non duplicated number is: " << non_duplicated_;
            LIBTB_REPORT_DEBUG(ss.str());
        }

        d.push_back(non_duplicated_);
        int cnt = OPT_N - 1;
        while (cnt) {
            const DatT duplicated =
                libtb::random_integer_in_range((1 << OPT_W) - 1);
            if (non_duplicated_ != duplicated) {
                std::stringstream ss;
                ss << "Duplicated number is: " << duplicated;
                LIBTB_REPORT_DEBUG(ss.str());
                d.push_back(duplicated);
                d.push_back(duplicated);
                cnt -= 2;
            }
        }
        std::random_shuffle(d.begin(), d.end());

        state_upt_ = true;
        for (int i = 0; i < OPT_N; i++)
        {
            const DatT duplicated = d[i];
            state_id_ = i;
            state_dat_ = duplicated;
            t_wait_posedge_clk();
        }
        state_upt_ = false;
    }

    bool run_test()
    {
        t_wait_reset_done();
        LIBTB_REPORT_INFO("Stimulus starts...");

        b_configure_state();

        cntrl_start_ = true;
        t_wait_posedge_clk();
        cntrl_start_ = false;

        wait(cntrl_busy_r_.negedge_event());
        t_wait_posedge_clk();

        if (cntrl_dat_r_ != non_duplicated_) {
            std::stringstream ss;
            ss << "Mismatch detected"
               << " Expected: " << non_duplicated_
               << " Actual: " << cntrl_dat_r_
                ;
            LIBTB_REPORT_ERROR(ss.str());
        }

        wait(1000, SC_NS);

        LIBTB_REPORT_INFO("Stimulus ends.");
        return false;
    }

    DatT non_duplicated_;
#define __declare_signals(__type, __name)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
    UUT uut_;
};

int sc_main (int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<MissingDuplicatedWordTb>(argc, argv).start();
}
