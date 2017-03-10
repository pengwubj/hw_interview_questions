# Origin

# Company

Apple

# Problem Statement

Commands are issued to some agent. Reponses return from the agent after some
undefined latency. Derive logic that will compute the average latency
experienced by each command. Commands cannot be TAGGED and shall be considered
to be opaque to the logic. Additionally, the number of commands issued is
unknown and unbounded.

# Commentary

This question is without doubt non-trivial to someone without prior knowledge of
the solution, however it is a common question asked by some of the larger
companies, particularlly Apple.

It turns out, that the latency can be computed relatively trivially using only
three counters.

* At the start of the interval of interest, the counters are reset to 0.
* Counter 1 tracks the total number of commands issued to the agent over the
  interval of interest. This is computed by simply incrementing the counter each
  time a command is issued.
* Counter 2 tracks the total number of commands that are presently inflight at
  any point in time. The counter is incremented on issue, and decremented on
  retirement/committal.
* Counter 3 tracks the aggregate latency of all commands. The counter is
  incremented on each cycle by the current count retained by Counter 2.
* Average latency is computed by dividing the value of Counter 3 by Counter 1
  upon completion of the interval of interest.

## Notes:

Division is a non-trivial and costly function to perform in hardware. Therefore,
the majority of implementations simply expose Counter 1 and Counter 3 as
software-visible registers and the latency computed in software.

The key to understanding the solution is with Counter 3. It is impossible to
compute the latency of any single command in the system. Instead, one must
compute the overall latency experience by ALL commands in the interval of
interest. From this, the average latency can be computed trivially.
