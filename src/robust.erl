%% Author: vhg
%% Created: Jun 8, 2010
%% Description: TODO: Add description to robust
-module(robust).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0]).
-export([loop/4,start_win/1]).

%%
%% API Functions
%%



%%
%% Local Functions
%%


loop(Quit, Spawn, Error, Parent_PID) ->
  receive
    {gs,Quit,click,_,_} ->
      io:format("~w exiting normally~n",[self()]),
      exit(quit);
    {gs,Spawn,click,_,_} ->
      Child_PID =spawn_link(robust,start_win,[self()]),
      io:format("~w spawning child ~w~n",[self(),Child_PID]),
      loop(Quit,Spawn,Error, Parent_PID);
    {gs,Error,click,_,_} ->
      exit(die);
    {'EXIT',PID,quit} ->
      if PID == Parent_PID -> 
           io:format("~w received quit from parent ~w.~n",
                     [self(),Parent_PID]),
           exit(quit);
         true ->
           loop(Quit,Spawn,Error, Parent_PID)
      end;
    {'EXIT',PID,die} ->
      if PID == Parent_PID -> 
           io:format("~w received error from parent ~w.~n",
                     [self(),Parent_PID]),
           exit(die);
         true ->
           spawn_link(robust,start_win,[self()]),
           loop(Quit,Spawn,Error, Parent_PID)
      end
  end.

start() ->
  spawn(robust,start_win,[self()]).

start_win(Parent_PID) ->
  GS=gs:start(),
  WH = [{width,200},{height,40}],
  Win = gs:create(window,GS,WH),
  gs:frame(packer,Win,{packer_x,[{stretch,1},{stretch,1},{stretch,1}]}),
  Quit  = gs:button(packer,[{label,{text,"Quit"}}  ,{pack_x,1}]),
  Spawn = gs:button(packer,[{label,{text,"Spawn"}} ,{pack_x,2}]),
  Error = gs:button(packer,[{label,{text,"Error"}} ,{pack_x,3}]),
  gs:config(packer,WH),
  process_flag(trap_exit,true),
  gs:config(Win,{map,true}),
  loop(Quit, Spawn, Error, Parent_PID).