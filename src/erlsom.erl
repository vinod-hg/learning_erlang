%% Author: vhg
%% Created: Mar 5, 2010
%% Description: TODO: Add description to erlsom
-module(erlsom).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0]).

%%
%% API Functions
%%



%%
%% Local Functions
%%

start() ->
	Xml = '<foo attr="baz"><bar>x</bar><bar>y</bar></foo>',
	erlsom:parse_sax(Xml, [], fun(Event, Acc) -> io:format("~p~n", [Event]), Acc end).
