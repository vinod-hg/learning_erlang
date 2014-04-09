%% Author: vhg
%% Created: Mar 4, 2010
%% Description: TODO: Add description to concu
-module(concurrent).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0]).
-export([start_something/0,say_something/2]).	%need to export the function that is spawned

-export ([start_message/0 ,ping/2 ,pong/0] ).

-export([start_reg_message/0, ping_reg/1, pong_reg/0]).

-export([start_ping/1, start_pong/0, pingEx/2, pongEx/0]).

%%
%% API Functions
%%



%%
%% Local Functions
%%

% spawning processes

say_something(_,0)->
	done;
say_something(What,Times)->
	io:format("~p~n",[What]),		%~p instead of ~w
	say_something(What,Times-1).

start_something()->
	spawn(concurrent,say_something,[hello,3]),
	spawn(concurrent,say_something,[goodbye,3]).



% Message passing

ping(0,Pong_PID) ->
	Pong_PID ! finished,	% ! sends the message (any erlang term) to process (identified by PID)
 	io:format("Ping finished~n",[]);

ping(Times, Pong_PID)->
	Pong_PID ! {ping,self()},	% self() returns the PID of its process
	receive
		pong->					% Patern (message) received
			io:format("Ping received pong. Pong_PID:~w ~n",[Pong_PID])
	end,
	ping(Times-1,Pong_PID).


pong() ->
	receive
		finished ->
			io:format("Pong finished~n",[]);
		{ping, Ping_PID} ->
			io:format("Pong reveived ping. Ping_PID received:~w~n",[Ping_PID]),
			Ping_PID ! pong,
			pong()
	end.

start_message() ->
	Pong_PID = spawn(concurrent,pong,[]),
	_ = spawn(concurrent,ping,[3,Pong_PID]).



%register process name

%once registered..erlang machine needs to be restarted to register the same or needs to unregister it
ping_reg(0) ->
    pong ! finished,
    io:format("ping finished~n", []);

ping_reg(N) ->
    pong ! {ping, self()},
    receive
        pong ->
            io:format("Ping received pong~n", [])
    end,
    ping_reg(N - 1).

pong_reg() ->
    receive
        finished ->
            io:format("Pong finished~n", []);
        {ping, Ping_PID} ->
            io:format("Pong received ping~n", []),
            Ping_PID ! pong,
            pong_reg()
    end.

start_reg_message() ->
	unregister,					%unregisters before register the process with atom name
    register(pong, spawn(concurrent, pong_reg, [])),
    spawn(concurrent, ping_reg, [3]).





%Distributed programing

pingEx(0,Pong_Node)->
	 {pong,Pong_Node} ! finished,
	 io:format("ping finished~n");

pingEx(Times,Pong_Node)->
	{pong,Pong_Node} ! {ping,self()},
	receive
		pong ->
			io:format("ping received pong~n",[])
	end,
	pingEx(Times-1, Pong_Node).

pongEx()->
	receive
		finished ->
			io:format("pong finished ~n",[]),
			write("Finished Ponging");
		{ping,Ping_PID}->
			io:format("pong reveived ping~n",[]),
			Ping_PID ! pong,
			pongEx()
	end.
	 
	 
start_ping(Pong_Node)->
	write("Start Pinging"),
	spawn(concurrent,pingEx,[3,Pong_Node]).

start_pong()->
	%unregister,
	write("Start Ponging"),
	register(pong,spawn(concurrent,pongEx,[])).

start()->
	write("hi"),
	start_pong().

write(L) ->
    {ok, S} = file:open("C:/test.log", write),
   	io:format(S, "~p.~n",[L]),
    file:close(S).


