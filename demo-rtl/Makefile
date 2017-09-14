################################################################################
##
## Filename:	rtl/Makefile
##
## Project:	A Wishbone Controlled PWM (audio) controller
##
## Purpose:	To direct the Verilator build of the PWM example demo sources.
##		The result is C++ code (built by Verilator), that is then built
##	(herein) into an executable library.
##
## Targets:	The default target, all, builds the target test, which includes
##		the libraries necessary for Verilator testing.  It also builds
##	the pdmdemo target--building a C++ program which can be used to drive
##	this test via Verilator.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
##
## Copyright (C) 2017, Gisselquist Technology, LLC
##
## This program is free software (firmware): you can redistribute it and/or
## modify it under the terms of  the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
## target there if the PDF file isn't present.)  If not, see
## <http://www.gnu.org/licenses/> for a copy.
##
## License:	GPL, v3, as defined and found on www.gnu.org,
##		http://www.gnu.org/licenses/gpl.html
##
################################################################################
##
##
all:	test pdmdemo
FBDIR := .
VDIRFB:= $(FBDIR)/obj_dir

.PHONY: test
test: $(VDIRFB)/Vtoplevel__ALL.a
VOBJ := obj_dir
SUBMAKE := $(MAKE) --no-print-directory --directory=$(VOBJ) -f
ifeq ($(VERILATOR_ROOT),)
VERILATOR := verilator
VERILATOR_ROOT ?= $(shell bash -c '$(VERILATOR) -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
else
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif
export $(VERILATOR)
VROOT := $(VERILATOR_ROOT)
VINCD := $(VROOT)/include
VINC  := -I$(VINCD) -I$(VINCD)/vlstd -I$(VDIRFB)
VFLAGS := -Wall -MMD --trace -y ../rtl -cc

$(VDIRFB)/Vtoplevel__ALL.a: $(VDIRFB)/Vcordic.h $(VDIRFB)/Vcordic.cpp
$(VDIRFB)/Vtoplevel__ALL.a: $(VDIRFB)/Vcordic.mk
$(VDIRFB)/Vtoplevel.h $(VDIRFB)/Vtoplevel.cpp $(VDIRFB)/Vtoplevel.mk: toplevel.v

$(VDIRFB)/V%.cpp $(VDIRFB)/V%.h $(VDIRFB)/V%.mk: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

$(VDIRFB)/V%__ALL.a: $(VDIRFB)/V%.mk
	$(SUBMAKE) V$*.mk

.PHONY: clean
clean:
	rm -rf $(VDIRFB)/

pdmdemo: pdmdemo.cpp $(VDIRFB)/Vtoplevel__ALL.a
	g++ -Wall $(VINC) $(VINCD)/verilated.cpp $(VINCD)/verilated_vcd_c.cpp $^ -o pdmdemo

#
# Note Verilator's dependency created information, and include it here if we
# can
DEPS := $(wildcard $(VDIRFB)/*.d)

ifneq ($(DEPS),)
include $(DEPS)
endif
