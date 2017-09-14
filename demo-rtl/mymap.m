%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Filename: 	mymap.m
%%
%% Project:	A Wishbone Controlled PWM (audio) controller
%%
%% Purpose:	This file generates my favorite spectrogram color map.  The map
%%		is designed so that zero maps to black, and one maps to white.
%%	In between the two extremes, the color goes from black to blue, red,
%%	orange, yellow, and then white.
%%
%%	The one argument given to the colormap is the number of colors
%%	you would like to have in your map.  64 is often sufficient.
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
function [map] = mymap(nclrs)

	map = zeros(nclrs,3);
	idx = ((1:nclrs)-1)/(nclrs-1);

	map(:,1) = 1 - cos((idx-1/3)*3*pi)';
	map((idx<1/3),1) = 0;
	map((idx>2/3),1) = 1;

	map(:,2) = 1 - cos((idx-2/3)*3*pi)';
	map(idx<2/3,2) = 0;

	map(:,3) = 0.5 * (1-cos(idx*3*pi))';
	map((idx<5/6)&(idx>=2/3),3) = 0;
	map((idx>=5/6),3) = 1-cos((idx(idx>=5/6)-2/3)*1.5*pi)';

	map(map>1.0) = 1.0;
	map(map<0.0) = 0.0;
