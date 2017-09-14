# A demonstration of the Improved PWM waveform

This directory contains the files necessary to build a demonstration of the
[improved PWM](../rtl/wbpwmaudio.v) waveform used in this repository.  The
demonstration is designed to work both in a Verilator based simulation
(pdmdemo.cpp), as well as with a board having a single PMod AMP2, switch, LED,
and a 100MHz clock input.

The [toplevel Verilog file](toplevel.v) should be easily recognizable as
[toplevel.v](toplevel.v).  This contains the [cordic.v](cordic.v) component to
generate a sine wave as the test signal, as well as components to turn this
test signal into both a [traditional PWM](traditionalpwm.v) output as well as
the [improved version](../rtl/wbpwmaudio.v) found within this repository.
The [toplevel design](toplevel.v) will either output a 440 Hz tone, or a swept
tone running from 110Hz to about 27.3kHz, depending upon which part of the
test sequence is being run.

The `DEF_RELOAD` parameter within toplevel.v can be used to adjust the PWM
interval for the [traditional PWM](traditionalpwm.v), or sample interval for
the [improved version](../rtl/wbpwmaudio.v).  Likewise, when run on actual
hardware, the switch input will control which
waveform is produced--either the
[traditional PWM](traditionalpwm.v) or the
[improved waveform](../rtl/wbpwmaudio.v).

These files can also be composed within a
[Verilator](https://www.veripool.org/wiki/verilator) based simulation.  In this
case [pdmdemo.cpp](pdmdemo.cpp) forms the main simulation component.  A boolean
value within it, `traditional_pwm`, can be used to control whether or not the
file downsamples and outputs a [traditional PWM](traditionalpwm.v) signal or
the [improved version](../rtl/wbpwmaudio.v).  Likewise,
there's a commented line that you can use to generate a VCD file which can be
used to view traces of the logic within this demo.  This demonstration file
will also produce a file of 64-bit doubles (overkill, I know) containing
downsampled audio samples at 44.1kHz.  This audio file, named wavfp.dbl, can
be processed within
[Octave](https://www.gnu.org/software/octave)
by using [showspectrogram](showspectrogram.m), to view a spectrogram of the
data.

If you take the time to run the [simulation](pdmdemo.cpp), you'll clearly see
that the [improved PWM](../rtl/wbpwmaudio.v) waveform is much cleaner:
it doesn't include unwanted harmonics, nor does it include any artificial
features (beyond any expected aliasing products, present in both).
The [traditional PWM](traditionalpwm.v) waveform, on the other hand, cannot
seem to be able to produce a clear tone without also creating unwanted
harmonics.  This effect is only worsened when the PWM period is within
hearing range, such as when the period is the reciprocal of 8kHz.
