%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	showspectrogram.m
%%
%% Project:	A Wishbone Controlled PWM (audio) controller
%%
%% Purpose:	To generate a spectrogram image which can then be used to
%%		evaluate the wavfp.dbl file produced by the pdmdemo executable
%%	in this directory.
%%
%%	This script has been tested with Octave, and it is known to work with
%%	Octave.  While it may work within Matlab as well, no representation is
%%	being made to that effect.
%%
%% Creator:	Dan Gisselquist, Ph.D.
%%		Gisselquist Technology, LLC
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Copyright (C) 2017, Gisselquist Technology, LLC
%%
%% This program is free software (firmware): you can redistribute it and/or
%% modify it under the terms of the GNU General Public License as published
%% by the Free Software Foundation, either version 3 of the License, or (at
%% your option) any later version.
%%
%% This program is distributed in the hope that it will be useful, but WITHOUT
%% ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
%% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
%% for more details.
%%
%% You should have received a copy of the GNU General Public License along
%% with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
%% target there if the PDF file isn't present.)  If not, see
%% <http://www.gnu.org/licenses/> for a copy.
%%
%% License:	GPL, v3, as defined and found on www.gnu.org,
%%		http://www.gnu.org/licenses/gpl.html
%%
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%
function [img] = showspectrogram(fname)
	% Read the waveform into memory
	fid = fopen(fname,'r');
	dat = fread(fid, inf, 'double');
	fclose(fid);
	
	% You can plot it at this point if you would like
	% plot(dat);
	
	sample_rate   = 44.1e3;
	window_length = 512; % Size of the FFT
	Nc = 256; % Number of colors
	
	h = hanning(window_length); % About 1 ms
	rows = (length(dat)-length(h)) / length(h) * 2
	img = zeros(length(h)/2, rows);
	size(img)
	
	for n=1:rows
		cut = dat((1:length(h)) + (n-1)*length(h)/2);
		cutf = abs(fft(cut.*h)).^2;
		img(:,n) = cutf(1:(length(h)/2));
	end
	
	mintime = 0;
	maxtime = rows / sample_rate * window_length / 2;
	minfreq = 0;
	maxfreq = 0.5 * sample_rate;
	
	% Normalize the image so that the maximum value is one.
	img = img ./ max(max(img));
	
	%
	% Turn out spectrogram image into dB
	%
	% Adding 1e-8 is useful for artificially forcing the floor of the
	% image to be at a particular value, as well as for keeping the log
	% from reporting values too negative to plot successfully.
	img = 10 * log(img + 1e-8)/log(10);
	
	img = (img + 80)/80;
	colormap(mymap(256));
	image([mintime, maxtime], [minfreq, maxfreq/1e3], img * Nc);
	ylabel('Frequency (kHz)');
	xlabel('Time (s)');

	% Trim this image output to the relevant portion of the output
	axis([0, 6.2, 0, maxfreq/1e3]);

% For the plot, comment out the img ./ max(max(img)) line, as well as the
% img = (img+80)/80 line.  Then you can call this as:
% img    = showspectrogram('pdm8k-weak.dbl');
% imgpwm = showspectrogram('pwm8k-weak.dbl');
%
% freq = (0:(window_length-1))/(window_length)*(sample_rate/2/1e3)
% plot(freq,img(:,1400),'b;PDM;',freq,imgpwm(:,1400),'r;PWM;');
% grid on; xlabel('Frequency (kHz)'); ylabel('Volume (dB)');
% axis([0,22,-70,50]);
