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
#include <array>
#include <sstream>
#include <algorithm>
#include <deque>
#include "Vmulti_counter.h"

#define PORTS(__func)                           \
    __func(cntr_pass, bool)                     \
    __func(cntr_id, IdT)                        \
    __func(cntr_op, OpT)                        \
    __func(cntr_dat, DatT)                      \
    __func(status_pass_r, bool)                 \
    __func(status_qry_r, bool)                  \
    __func(status_id_r, IdT)                    \
    __func(status_dat_r, DatT)

using IdT = uint32_t;
using OpT = uint32_t;
using DatT = uint32_t;

constexpr int OPT_CNTRS_N = 256;
constexpr int OPT_CNTRS_W = 32;

//
constexpr OpT OP_NOP  = 0x00;
constexpr OpT OP_INIT = 0x04;
constexpr OpT OP_INC  = 0x0C;
constexpr OpT OP_DEC  = 0x0D;
constexpr OpT OP_QRY  = 0x18;

std::string OpT_to_string(OpT op)
{
    switch (op)
    {
    case OP_NOP: return "NOP";
    case OP_INIT: return "INIT";
    case OP_INC: return "INC";
    case OP_DEC: return "DEC";
    case OP_QRY: return "QRY";
    }
    return "INVALID";
}

static std::vector<OpT> CMDS{OP_INC, OP_DEC, OP_QRY};

//
class MultiCounterTb : libtb::TopLevel
{
    typedef Vmulti_counter UUT_t;
public:

    SC_HAS_PROCESS(MultiCounterTb);
    MultiCounterTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __construct_signals(__name, __type)     \
          , __name##_(#__name)
          PORTS(__construct_signals)
#undef __construct_signals
    {
        wave_on("foo.vcd", uut_);
        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signals(__name, __type)          \
        uut_.__name(__name##_);
        PORTS(__bind_signals)
#undef __bind_signals

        SC_METHOD(m_checker);
        sensitive << e_tb_sample();

        std::fill_n(std::begin(expected_), OPT_CNTRS_N, DatT());
    }

private:

    bool run_test() {
        LIBTB_REPORT_INFO("Starting stimulus");

        LIBTB_REPORT_INFO("Initializing state");
        for (int i = 0; i < OPT_CNTRS_N; i++)
            b_issue_command(i, OP_INIT, libtb::random<DatT>());

        LIBTB_REPORT_INFO("Applying random stimulus");
        for (int i = 0; i < N_; i++)
            b_issue_command(
                libtb::random_integer_in_range(OPT_CNTRS_W-1),
                *libtb::choose_random(CMDS)
                );

        LIBTB_REPORT_INFO("Checking state");
        for (int i = 0; i < OPT_CNTRS_N; i++)
            b_issue_command(i, OP_QRY, 0);

        LIBTB_REPORT_INFO("Stimulus ends");
        return false;
    }

    void b_issue_idle() {
        cntr_pass_ = false;
        cntr_id_ = IdT();
        cntr_op_ = OpT();
        cntr_dat_ = DatT();
    }

    void b_issue_command(
        const IdT & id, const OpT & op, const DatT & dat = DatT()) {
        cntr_pass_ = true;
        cntr_id_ = id;
        cntr_op_ = op;
        cntr_dat_ = dat;
        t_wait_posedge_clk();
        {
            std::stringstream ss;
            ss << "Issue command:"
                << "{"
                << "ID=" << id << ","
                << "OP=" << OpT_to_string(op) << ","
                << "DAT=" << dat
                << "}";
           LIBTB_REPORT_DEBUG(ss.str());
        }
        switch (op) {
        case OP_INIT:
            expected_[id] = dat;
            break;
        case OP_INC:
            ++expected_[id];
            break;
        case OP_DEC:
            --expected_[id];
            break;
        }
        queue_.push_back(expected_[id]);
        b_issue_idle();
    }

    void m_checker() {
        if (status_pass_r_) {

            const DatT expected = queue_.front();
            queue_.pop_front();

            if (!status_qry_r_)
                return;

            const IdT id = status_id_r_;
            const DatT actual = status_dat_r_;

            std::stringstream ss;
            if (actual != expected) {
                ss << "Mismatch"
                   << " ID=" << id
                   << " EXPECTED=" << expected
                   << " ACTUAL=" << actual;
                LIBTB_REPORT_ERROR(ss.str());
            } else {
                ss << "State validated: "
                   << "{"
                   << "ID=" << id << ","
                   << "DAT=" << actual
                   << "}";
                LIBTB_REPORT_DEBUG(ss.str());
            }
        }
    }

    const int N_{100000};
    std::array<DatT, OPT_CNTRS_N> expected_;
    std::deque<DatT> queue_;
#define __declare_signals(__name, __type)     \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signals)
#undef __declare_signals
 public:
    Vmulti_counter uut_;
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;

    return LibTbSim<MultiCounterTb>(argc, argv).start();
}
