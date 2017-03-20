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
#include <array>
#include <deque>
//
#include "Vmulti_counter_variants.h"

#define PORTS(__func)                           \
    __func(cmd_pass, bool)                      \
    __func(cmd_id, IdT)                         \
    __func(cmd_op, OpT)                         \
    __func(cmd_dat, DatT)                       \
    __func(busy_r, bool)                        \
    __func(s1_pass_r, bool)                     \
    __func(s1_dat_r, DatT)                      \
    __func(s2_pass_r, bool)                     \
    __func(s2_dat_r, DatT)                      \
    __func(s3_pass_r, bool)                     \
    __func(s3_dat_r, DatT)

constexpr int OPT_CNTRS_N = 32;
constexpr int OPT_CNTRS_W = 32;

using IdT = uint32_t;
using OpT = uint32_t;
using DatT = uint32_t;

//
constexpr OpT OP_NOP  = 0x00;
constexpr OpT OP_INIT = 0x04;
constexpr OpT OP_INC  = 0x0C;
constexpr OpT OP_DEC  = 0x0D;
constexpr OpT OP_QRY  = 0x18;

class MultiCounterVariantsTb : libtb::TopLevel
{
public:
    typedef Vmulti_counter_variants UUT_t;
    SC_HAS_PROCESS(MultiCounterVariantsTb);
    MultiCounterVariantsTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __construct_signal(__name, __type)      \
        , __name##_(#__name)
        PORTS(__construct_signal)
#undef __construct_signal
    {
        SC_METHOD(m_trace);
        dont_initialize();
        sensitive << e_tb_sample();

        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signal(__name, __type)            \
        uut_.__name(__name##_);
        PORTS(__bind_signal)
#undef __bind_signals
    }

    void m_trace()
    {
        if (s1_pass_r_)
        {
            std::stringstream ss;
            ss << "S1 Query returns: " << s1_dat_r_;
            LIBTB_REPORT_INFO(ss.str());
        }

        if (s2_pass_r_)
        {
            std::stringstream ss;
            ss << "S2 Query returns: " << s2_dat_r_;
            LIBTB_REPORT_INFO(ss.str());
        }

        if (s3_pass_r_)
        {
            std::stringstream ss;
            ss << "S3 Query returns: " << s3_dat_r_;
            LIBTB_REPORT_INFO(ss.str());
        }
    }

    void cmd_idle()
    {
        cmd_pass_ = false;
        cmd_op_ = OpT();
        cmd_dat_ = DatT();
    }

    void b_cmd_issue(const IdT id, const OpT op, const DatT dat = DatT())
    {
        cmd_pass_ = true;
        cmd_id_ = id;
        cmd_op_ = op;
        cmd_dat_ = dat;
        t_wait_posedge_clk();
        switch (op)
        {
        case OP_INIT:
            cntrs_[id] = dat;
            break;
        case OP_INC:
            ++cntrs_[id];
            break;
        case OP_DEC:
            --cntrs_[id];
            break;
        case OP_QRY:
            for (int i = 0; i < OPT_CNTRS_N; i++)
                expect_[i].push_back(cntrs_[id]);
            break;
        }
        cmd_idle();
    }

    bool run_test() {
        cmd_idle();
        t_wait_posedge_clk(10);
        LIBTB_REPORT_INFO("Stimulus starts...");

        b_cmd_issue(0, OP_INIT, 10);
        b_cmd_issue(0, OP_INC);
        b_cmd_issue(0, OP_INC);
        b_cmd_issue(0, OP_INC);
        b_cmd_issue(0, OP_INC);
        b_cmd_issue(0, OP_QRY);
        t_wait_posedge_clk(10);

        LIBTB_REPORT_INFO("Stimulus ends.");
        return true;
    }

    std::array<DatT, OPT_CNTRS_N> cntrs_;
    std::array<std::deque<DatT>, OPT_CNTRS_N> expect_;

public:
#define __declare_signal(__name, __type)       \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signal)
#undef __declare_signal
    UUT_t uut_;
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<MultiCounterVariantsTb>(argc, argv).start();
}
