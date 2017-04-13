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
#include <list>
#include <deque>
#include <algorithm>
#include <sstream>
#include <iterator>
//
#include "Vsorted_lists.h"

#define ISSUE_DELAY

#define PORTS(__func)                           \
    __func(upt_vld, bool)                       \
    __func(upt_id, IdT)                         \
    __func(upt_op, OpT)                         \
    __func(upt_key, KeyT)                       \
    __func(upt_size, SizeT)                     \
    __func(upt_error_vld_r, bool)               \
    __func(upt_error_id_r, IdT)                 \
    __func(qry_vld, bool)                       \
    __func(qry_id, IdT)                         \
    __func(qry_level, LevelT)                   \
    __func(qry_resp_vld_r, bool)                \
    __func(qry_key_r, KeyT)                     \
    __func(qry_size_r, SizeT)                   \
    __func(qry_error_r, bool)                   \
    __func(qry_listsize_r, ListSizeT)           \
    __func(ntf_vld_r, bool)                     \
    __func(ntf_id_r, IdT)                       \
    __func(ntf_key_r, KeyT)                     \
    __func(ntf_size_r, SizeT)

enum Op {
  OP_CLEAR = 0, OP_ADD = 1, OP_DELETE = 2, OP_REPLACE = 3
};
static const std::list<int> OPS{OP_CLEAR, OP_ADD, OP_DELETE, OP_REPLACE};
std::string op_to_string(int op) {
    switch (op) {
    case OP_CLEAR: return "OP_CLEAR";
    case OP_ADD: return "OP_ADD";
    case OP_DELETE: return "OP_DELETE";
    case OP_REPLACE: return "OP_REPLACE";
    default:{
        std::stringstream ss;
        ss << "{UNKNOWN:" << op << "}";
        return ss.str();
    }
    }
}

constexpr int OPT_UPDATES = 100000;
constexpr int OPT_QUERIES = 100000;
constexpr int N = 4;
constexpr int M = 64;

using IdT = uint32_t;
using OpT = uint32_t;
using KeyT = vluint64_t;
using SizeT = uint32_t;
using ListSizeT = uint32_t;
using LevelT = uint32_t;

struct Query
{
    IdT id;
    LevelT l;
};

struct Update
{
    IdT id;
    OpT op;
    KeyT k;
    SizeT s;
};

struct Entry
{
    KeyT key;
    SizeT size;
    std::string to_string() const {
        std::stringstream ss;
        ss << "{"
           << std::hex
           << "key:" << key << ","
           << "size:" << size
           << "}"
            ;
        return ss.str();
    }
};

struct QueryResult
{
    KeyT key;
    SizeT size;
    ListSizeT listsize;
    bool error;

    std::vector<Entry> dbg_;

    std::string to_string() const {
        std::stringstream ss;
        ss << "{"
           << std::hex
           << "key:" << key << ","
           << "size:" << size << ","
           << "listsize:" << listsize << ","
           << "error:" << error
           << "}"
            ;
        return ss.str();
    }
};

bool operator==(const QueryResult &l, const QueryResult &r) {
    bool eq = true;

    // If query has errored, all bets are off.
    if ((r.error == l.error) && r.error)
        return true;

    eq &= (r.key == l.key);
    eq &= (r.size == l.size);
    eq &= (r.listsize == l.listsize);
    return eq;
}

struct MachineModel
{
    using ListTable = std::array<std::vector<Entry>, M>;

    // Construct a random query based upon the known state of the machine.
    //
    Update random_update() {
        Update u;

        u.id = libtb::random_integer_in_range(M - 1);
        u.op = random_op(u.id, u.k);
        u.s = libtb::random<SizeT>();
        return u;
    }

    Query random_query() {
        Query q;

        int rnds = 100;
        const int allow_error = (libtb::random_integer_in_range(100) < 10);
        while (rnds--) {

            const int id = libtb::random_integer_in_range(M - 1);
            const std::size_t sz = t_[id].size();
            if (sz != 0 || allow_error) {
                const LevelT l = libtb::random_integer_in_range(N - 1);
                if (l < sz || allow_error) {
                    q.id = id;
                    q.l = l;
                    return q;
                }
            }
        }
        return q;
    }

    void apply_query(const Query & q, QueryResult & qr) {

        {
            std::stringstream ss;
            ss << "Issuing Query:"
               << "{"
               << "id:" << q.id << ","
               << "level:" << q.l
               << "}"
                ;
            LIBTB_REPORT_DEBUG(ss.str());
        }

        auto & es = t_[q.id];

        qr.key = 0;
        qr.size = 0;
        qr.listsize = 0;
        qr.error = 0;

        if (q.l >= es.size()) {
            qr.error = true;
            return;
        }

        // Sort by key
        std::sort(es.begin(), es.end(),
                  [](const Entry &l, const Entry &r) {
                      return (l.key > r.key);
                  });
        auto it = es.begin();
        std::advance(it, q.l);
        qr.key = it->key;
        qr.size = it->size;
        qr.listsize = es.size();
        qr.dbg_ = es;
    }

    bool update(IdT id, OpT op, KeyT k = KeyT(), SizeT s = SizeT()) {

        {
            std::stringstream ss;
            ss << "Applying state update:"
               << "{"
               << "id:" << id << ","
               << "op:" << op_to_string(op) << ","
               << std::hex
               << "key:" << k << ","
               << "size:" << s
               << "}"
                ;
            LIBTB_REPORT_DEBUG(ss.str());
        }

        bool error = false;
        switch (op) {
        case OP_CLEAR:
        {
            t_[id].clear();
        }
        break;

        case OP_ADD:
        {
            const Entry e{k, s};

            if (t_[id].size() < N)
                t_[id].push_back(e);
            else
                error = true;
        }
        break;

        case OP_DELETE:
        {
            auto it = std::find_if(t_[id].begin(), t_[id].end(),
                                [&](const Entry & e) {
                                    return (e.key == k);
                                });

            if (it != t_[id].end())
                t_[id].erase(it);
            else
                error = true;
        }
        break;

        case OP_REPLACE:
        {
            auto it = std::find_if(t_[id].begin(), t_[id].end(),
                                [&](const Entry & e) {
                                    return (e.key == k);
                                });

            if (it != t_[id].end())
                it->size = s;
            else
                error = true;
        }
        break;

        }
        return error;
    }

private:

    // Intelligently construct a opcode based upon the current machine
    // with appropriate weights where required.
    //
    OpT random_op(IdT id, KeyT & k) {

        auto &es = t_[id];
        int rnds = 10;
        OpT r = OP_CLEAR;
        k = 0;

        const int allow_error = (libtb::random_integer_in_range(100) < 10);
        while (rnds--) {
            const std::size_t sz = es.size();
            const int i = libtb::random_integer_in_range(1000);

            if (i < 300) {
                // OP_ADD
                if (sz < N || allow_error) {
                    k = libtb::random<KeyT>();
                    return OP_ADD;
                }

            } else if (i < 600) {
                // OP_DELETE
                if (sz != 0 || allow_error) {
                    if (!allow_error)
                        k = libtb::choose_random(es.begin(), es.end())->key;
                    return OP_DELETE;
                }

            } else if (i < 900) {
                // OP_REPLACE
                if (sz != 0 || allow_error) {
                    if (!allow_error)
                        k = libtb::choose_random(es.begin(), es.end())->key;
                    return OP_REPLACE;
                }
            } else {
                return OP_CLEAR;
            }

        }
        return OP_CLEAR;
    }

    ListTable t_;
};

struct SortedListsTb : libtb::TopLevel
{
    //
    using UUT = Vsorted_lists;
    SC_HAS_PROCESS(SortedListsTb);
    SortedListsTb(sc_core::sc_module_name mn = "t")
        : uut_("uut")
#define __construct_signal(__name, __type)      \
          , __name##_(#__name)
          PORTS(__construct_signal)
#undef __construct_signal
    {
        SC_THREAD(t_update);
        SC_METHOD(m_query_checker);
        dont_initialize();
        sensitive << e_tb_sample();

        uut_.clk(clk());
        uut_.rst(rst());
#define __bind_signal(__name, __type)           \
        uut_.__name(__name##_);
        PORTS(__bind_signal)
#undef __bind_signals
    }

    void m_query_checker() {
        if (qry_resp_vld_r_) {

            if (r_list_.size() == 0)
            {
                LIBTB_REPORT_ERROR("Unexpected response");
                return;
            }

            const QueryResult expected = r_list_.front();
            r_list_.pop_front();
            const QueryResult actual{
                qry_key_r_, qry_size_r_, qry_listsize_r_, qry_error_r_};
            if (!(expected == actual)) {
                std::stringstream ss;
                ss << "Mismatch detected: "
                   << " Actual:" << actual.to_string()
                   << " Expected:" << expected.to_string();
                LIBTB_REPORT_ERROR(ss.str());

                // Report LIST state.
                for (auto & e : expected.dbg_)
                    LIBTB_REPORT_DEBUG(e.to_string());
            } else {
                std::stringstream ss;
                ss << "Query response validated:" << actual.to_string();
                LIBTB_REPORT_DEBUG(ss.str());
            }

        }
    }

    void t_update() {
        t_wait_reset_done();
        LIBTB_REPORT_INFO("Setting configuration...");

        for (int i = 0; i < OPT_UPDATES; i++)
        {
            const Update u = mdl_.random_update();
            b_issue_upt(u.id, u.op, u.k, u.s);
        }
        LIBTB_REPORT_INFO("Configuration set...");

        t_wait_posedge_clk(10);
        update_done_event_.notify();
    }

    void upt_idle() {
        upt_vld_ = false;
        upt_id_ = IdT();
        upt_op_ = OpT();
        upt_key_ = KeyT();
        upt_size_ = SizeT();
    }

    void b_issue_upt(IdT id, OpT op, KeyT k = KeyT(), SizeT s = SizeT()) {
        upt_vld_ = true;
        upt_id_ = id;
        upt_op_ = op;
        upt_key_ = k;
        upt_size_ = s;
        t_wait_posedge_clk(1);
        mdl_.update(id, op, k, s);
        upt_idle();
#ifdef ISSUE_DELAY
        t_wait_posedge_clk(1);
#endif
    }

    void qry_idle() {
        qry_vld_ = false;
        qry_id_ = IdT();
        qry_level_ = LevelT();
    }

    void b_issue_qry(const Query & q) {
        qry_vld_ = true;
        qry_id_ = q.id;
        qry_level_ = q.l;
        t_wait_posedge_clk();
        QueryResult qr;
        mdl_.apply_query(q, qr);
        r_list_.push_back(qr);
        qry_idle();
    }

    bool run_test() {
        wait(update_done_event_);
        LIBTB_REPORT_INFO("Stimulus starts...");

        for (int i = 0; i < OPT_QUERIES; i++) {
            const Query q = mdl_.random_query();
            b_issue_qry(q);
        }
        t_wait_posedge_clk(10);
        LIBTB_REPORT_INFO("Stimulus ends...");
        return false;
    }
    MachineModel mdl_;
    std::deque<QueryResult> r_list_;
    sc_core::sc_event update_done_event_;
#define __declare_signal(__name, __type)        \
    sc_core::sc_signal<__type> __name##_;
    PORTS(__declare_signal)
#undef __declare_signal
    UUT uut_;
};

int sc_main(int argc, char **argv)
{
    using namespace libtb;
    return LibTbSim<SortedListsTb>(argc, argv).start();
}
