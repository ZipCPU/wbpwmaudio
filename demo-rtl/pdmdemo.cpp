////////////////////////////////////////////////////////////////////////////////
//
// Filename:	pdmdemo.cpp
//
// Project:	A Wishbone Controlled PWM (audio) controller
//
// Purpose:	A Verilator driver to demonstrate, off-line, if the PDM
//		approach used by wbpwmaudio works.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2015-2020, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
#include <stdio.h>
#include <math.h>

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtoplevel.h"
#include "testb.h"

// Verilator changed their naming convention somewhere around version 3.9 or
// so.
#ifdef	NEW_VERILATOR
#define	seq_step	toplevel__DOT__seq_step
#else
#define	seq_step	v__DOT__seq_step
#endif

#define	CLOCK_RATE_HZ	100000000	// FPGA clock rate
#define	SAMPLE_RATE_HZ	44100		// Our output (generated) sample rate
#define	AUDIO_TOP_HZ	22000		// The filter's cutoff frequency

//
// We are going to use an overkill filter, generated via the crude manner of
// windowing an "ideal" filter.  ("ideal" filters are never "ideal" ... but
// that's beside the point.)  The problem with this is that the filter has
// arbitrarily way too many taps.  Hence, we'll use a filter with FIRLEN
// taps and leave examples with fewer taps for any paying customers.
const int	FIRLEN = 65536*8;

double  sinc(double f) {
        double  x = M_PI * f;
        // if (fabs(f)<1e-2)
        if (fabs(f)<3e-1) {
                double  xsq = x * x;
                // sin(x) = x - x^3/3! + x^5/5! - x^7/7! + x^9/9! - x^11/11!...
                //sinc(x) = 1 - x^2/3!+x^4/5!-x^6/7!+x^8/9!-x^10/11!...
                return 1.0 - (xsq/6.0)
                        * (1.0 - (xsq/20.0)
                        * (1.0 - (xsq/42.0)
                        * (1.0 - (xsq/72.0)
                        * (1.0 - (xsq/110.0)
                        * (1.0 - (xsq/156.0))))));
        } else
                return sin(x)/x;
}

//
// class PDMDEMO is a wrapper class around the Verilator generated simulation
// component.
//
class	PDMDEMO : public TESTB<Vtoplevel> {
	// Resampling filter taps
	double		*m_taps;
	// Resampler variables, telling us when to produce the next output
	double		m_subsample, m_step;
	// The file to place these values into
	FILE		*m_wavfp;
	// Filter memory
	int		*m_firmem, m_firpos;
public:

	PDMDEMO(void) {
		// Our filter cutoff
		const	double	fc = (double)AUDIO_TOP_HZ
					/ (double)CLOCK_RATE_HZ;

		// Allocate memory for taps and data values
		m_taps = new double[FIRLEN];
		m_firmem = new int[FIRLEN];
		m_firpos = 0;

		for(int i=0; i<FIRLEN; i++) {
			double	window, t;

			m_firmem[i] = 0;

			// Blackman Window --- see Oppenheim and Schafer
			// for more info.
			t = (i+1.0-FIRLEN/2)/(FIRLEN+1.0);
			window = 0.42
				+0.50 * cos(2.0*M_PI*t)
				+0.08 * cos(4.0*M_PI*t);

			// An "ideal" lowpass filter, with cutoff at fc
			// (fc is in units of normalized frequency)
			t = (i+1.0-FIRLEN/2);
			m_taps[i] = 2.0 * fc * sinc(2.0 * fc * t); // sin(2.0 * M_PI * fc * t) / (M_PI * t);

			// Apply the window to the filter tap
			m_taps[i] *= window;

		}

		// We'll set the middle tap special, since sin(x)/x isn't
		// known for its convergence when x=0.
		// m_taps[FIRLEN/2-1] = 2.0 * fc;

		// In case you'd like to look at this filter, we'll dump its
		// taps to a file.
		m_wavfp = fopen("filter.dbl","w");
		fwrite(m_taps, sizeof(m_taps[0]), FIRLEN, m_wavfp);
		fclose(m_wavfp);

		// Otherwise, everything is going to be dumped to the
		// wavfp.dbl file.
		m_wavfp = fopen("wavfp.dbl","w");

		// Initialize the values we need to use for determining our
		// resample clock.
		m_subsample = 0.0;
		m_step = (double)SAMPLE_RATE_HZ / (double)CLOCK_RATE_HZ;
	}

	~PDMDEMO(void) {
		// Close our output waveform file
		if (m_wavfp)
			fclose(m_wavfp);
	}

	void	tick(void) {
		// Tick the clock.
		TESTB<Vtoplevel>::tick();

		// Examine the output
		// output = TESTB<Vtoplevel>::m_core->o_pwm;

		// If we are writing to an output file (should always be true)
		// then ...
		if (m_wavfp) {
			int	output;

			// Turn this output into a "voltage" centered upon
			// zero.  If the output is not shutdown, the voltage
			// will be dependent upon the pins value, and will
			// either be +/- one.  Otherwise, we'll just output a
			// zero value.
			if (m_core->o_shutdown_n)
				output = 2*(m_core->o_pwm&1) - 1;
			else
				output = 0;

			// Add this value to our filter memory, and adjust the
			// pointer to the oldest sample in memory.
			m_firmem[m_firpos++] = output;
			if (m_firpos >= FIRLEN)
				m_firpos = 0;

			// If it's time to run the filter to calculate a result,
			// ...
			m_subsample += m_step;
			if (m_subsample >= 1.0) {

				// Then apply the taps from the filter to our
				// data smaples.  Note that there will be some
				// amount of phase noise from using this
				// approach, since it essentially amounts to
				// applying a filter to get an instantaneous
				// output and then using a nearest neighbour
				// interpolator---rather than properly
				// getting any subsample resolution.
				//
				// For our purposes today, this should be good
				// enough.
				double	acc = 0.0;

				// First run through memory from the oldest
				// value until the end of the buffer
				for(int i=0; i+m_firpos < FIRLEN; i++)
					acc += m_taps[i] * m_firmem[m_firpos+i];
				// Then continue from the beginning of the
				// buffer to the most recent value.
				for(int i=FIRLEN-m_firpos; i < FIRLEN; i++)
					acc += m_taps[i] * m_firmem[m_firpos+i-FIRLEN];

				// Write the output out into a file.
				// The value is of type double.
				fwrite(&acc, sizeof(double), 1, m_wavfp);

				// Set us up to calculate when the next
				// sample will be at this rate.
				m_subsample -= 1.0;
			}
		}
	}
};

int main(int  argc, char **argv) {
	Verilated::commandArgs(argc, argv);
	// Create a class containing our design
	PDMDEMO	*tb = new PDMDEMO;

	// This should really be a command line parameter ...
	// Adjust this value to true to produce a traditional PWM output, false
	// to produce the "improved" PDM output.
	const	bool	traditional_pwm = false;

	printf("\n\n");
	if (traditional_pwm) {
		printf("Creating the output for a traditional PWM\n");
		tb->m_core->i_sw = 2;
	} else {
		// printf("Creating the output for the modified/improved PDM\n");
		// tb->m_core->i_sw = 0;
		printf("Creating the output for the LR PWM\n");
		tb->m_core->i_sw = 1;
	}
	printf("\n\n");

	// If you want to see a trace from this run, then uncomment the line
	// below.  Be aware, the trace file can quickly become many GB in
	// length!
	//
	// tb->opentrace("pdmdemo.vcd");

	//
	// Simulate ten seconds of our waveform generator
	for(int k=0; k< 10 * CLOCK_RATE_HZ; k++) {

		// Just so we believe its doing something, let's output
		// what step we are on, and what frequency is going into the
		// frequency generator.
		if ((k % (CLOCK_RATE_HZ/1000))==0) {
			double	secs = k / (double)CLOCK_RATE_HZ;
			if (tb->m_core->o_shutdown_n) {
				double	f = tb->m_core->seq_step;
				f = f * CLOCK_RATE_HZ / pow(2,34);
				printf("k = %10d clocks, %5.2f secs, f = %8.1f Hz\n", k, secs, f);
			} else
				printf("k = %10d clocks, %5.2f secs\n", k, secs);

		}

		// Step the simulation forward by a single clock tick
		tb->tick();
	}

	// Now that we're all done, delete the simulation and exit
	delete tb;
	exit(EXIT_SUCCESS);
}
