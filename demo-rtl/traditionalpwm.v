////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	traditionalpwm.v
//
// Project:	A Wishbone Controlled PWM (audio) controller
//
// Purpose:
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2015-2024, Gisselquist Technology, LLC
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
`default_nettype	none
//
module	traditionalpwm(i_clk, i_reset,
		// Wishbone interface
		i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data,
			o_wb_ack, o_wb_stall, o_wb_data,
		o_pwm, o_aux, o_int);
	parameter	DEFAULT_RELOAD = 16'd1814, // about 44.1 kHz @  80MHz
			//DEFAULT_RELOAD = 16'd2268,//about 44.1 kHz @ 100MHz
			NAUX=2, // Dev control values
			VARIABLE_RATE=0,
			TIMING_BITS=16;
	input	wire		i_clk, i_reset;
	input	wire		i_wb_cyc, i_wb_stb, i_wb_we;
	input	wire		i_wb_addr;
	input	wire	[31:0]	i_wb_data;
	output	reg		o_wb_ack;
	output	wire		o_wb_stall;
	output	wire	[31:0]	o_wb_data;
	output	reg		o_pwm;
	output	reg	[(NAUX-1):0]	o_aux;
	output	wire		o_int;


	// How often shall we create an interrupt?  Every reload_value clocks!
	// If VARIABLE_RATE==0, this value will never change and will be kept
	// at the default reload rate (defined up top)
	wire	[(TIMING_BITS-1):0]	w_reload_value;
	generate
	if (VARIABLE_RATE != 0)
	begin : GEN_VARIABLE_RATE
		reg	[(TIMING_BITS-1):0]	r_reload_value;
		initial	r_reload_value = DEFAULT_RELOAD;
		always @(posedge i_clk) // Data write
			if ((i_wb_stb)&&(i_wb_addr)&&(i_wb_we))
				r_reload_value <= i_wb_data[(TIMING_BITS-1):0]-1'b1;
		assign	w_reload_value = r_reload_value;
	end else begin : FIXED_RATE
		assign	w_reload_value = DEFAULT_RELOAD;
	end endgenerate

	//
	// The next value timer
	//
	// We'll want a new sample every w_reload_value clocks.  When the
	// timer hits zero, the signal ztimer (zero timer) will also be
	// set--allowing following logic to depend upon it.
	//
	reg				ztimer;
	reg	[(TIMING_BITS-1):0]	timer;
	initial	timer = DEFAULT_RELOAD;
	initial	ztimer= 1'b0;
	always @(posedge i_clk)
		if (i_reset)
			ztimer <= 1'b0;
		else
			ztimer <= (timer == { {(TIMING_BITS-1){1'b0}}, 1'b1 });

	always @(posedge i_clk)
		if ((ztimer)||(i_reset))
			timer <= w_reload_value;
		else
			timer <= timer - {{(TIMING_BITS-1){1'b0}},1'b1};

	//
	// Whenever the timer runs out, accept the next value from the single
	// sample buffer.
	//
	reg	[15:0]	sample_out;
	always @(posedge i_clk)
		if (ztimer)
			sample_out <= next_sample;


	//
	// Control what's in the single sample buffer, next_sample, as well as
	// whether or not it's a valid sample.  Specifically, if next_valid is
	// false, then the sample buffer needs a new value.  Once the buffer
	// has a value within it, further writes will just quietly overwrite
	// this value.
	reg	[15:0]	next_sample;
	reg		next_valid;
	initial	next_valid = 1'b1;
	initial	next_sample = 16'h8000;
	always @(posedge i_clk) // Data write
		if ((i_wb_stb)&&(i_wb_we)
				&&((!i_wb_addr)||(VARIABLE_RATE==0)))
		begin
			// We get a two's complement data from the bus.
			// Convert it here to an unsigned binary offset
			// representation
			next_sample <= i_wb_data[15:0] + { 1'b0, w_reload_value[15:1] } + 1'b1;
			next_valid <= 1'b1;
			if (i_wb_data[16])
				o_aux <= i_wb_data[(NAUX+20-1):20];
		end else if (ztimer)
			next_valid <= 1'b0;

	assign	o_int = (!next_valid);

	reg	[15:0]	pwm_counter;
	initial	pwm_counter = 16'h00;
	always @(posedge i_clk)
		if (ztimer)
			pwm_counter <= 0;
		else
			pwm_counter <= pwm_counter + 1'b1;

	always @(posedge i_clk)
		o_pwm <= (sample_out >= pwm_counter);

	//
	// Handle the bus return traffic.
	generate
	if (VARIABLE_RATE == 0)
	begin : FIXED_WB_RETURN
		// If we are running off of a fixed rate, then just return
		// the current setting of the aux registers, the current
		// interrupt value, and the current sample we are outputting.
		assign o_wb_data = { {(12-NAUX){1'b0}}, o_aux,
					3'h0, o_int, sample_out };
	end else begin : VAR_RATE_WB_RETURN
		// On the other hand, if we have been built to support a
		// variable sample rate, then return the reload value for
		// address one but otherwise the data value (above) for address
		// zero.
		reg	[31:0]	r_wb_data;
		always @(posedge i_clk)
			if (i_wb_addr)
				r_wb_data <= { (32-TIMING_BITS),w_reload_value};
			else
				r_wb_data <= { {(12-NAUX){1'b0}}, o_aux,
						3'h0, o_int, sample_out };
		assign	o_wb_data = r_wb_data;
	end endgenerate

	// Always ack on the clock following any request
	initial	o_wb_ack = 1'b0;
	always @(posedge i_clk)
		o_wb_ack <= (i_wb_stb);

	// Never stall
	assign	o_wb_stall = 1'b0;

	// Make Verilator happy.  Since we aren't using all of the bits from
	// the bus, Verilator -Wall will complain.  This just informs
	// V*rilator that we already know these bits aren't being used.
	//
	// verilator lint_off UNUSED
	wire	[14:0]	unused;
	assign	unused = { i_wb_cyc, i_wb_data[31:21], i_wb_data[19:17] };
	// verilator lint_on  UNUSED

endmodule
