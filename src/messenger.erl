%% Author: vhg
%% Created: Mar 5, 2010

%%% Message passing utility.  
%%% User interface:
%%% logon(Name)
%%%     One user at a time can log in from each Erlang node in the
%%%     system messenger: and choose a suitable Name. If the Name
%%%     is already logged in at another node or if someone else is
%%%     already logged in at the same node, login will be rejected
%%%     with a suitable error message.
%%% logoff()
%%%     Logs off anybody at at node
%%% message(ToName, Message)
%%%     sends Message to ToName. Error messages if the user of this 
%%%     function is not logged on or if ToName is not logged on at
%%%     any node.
%%%
%%% One node in the network of Erlang nodes runs a server which maintains
%%% data about the logged on users. The server is registered as "messenger"
%%% Each node where there is a user logged on runs a client process registered
%%% as "mess_client" 
%%%
%%% Protocol between the client processes and the server
%%% ----------------------------------------------------
%%% 
%%% To server: {ClientPid, logon, UserName}
%%% Reply {messenger, stop, user_exists_at_other_node} stops the client
%%% Reply {messenger, logged_on} logon was successful
%%%
%%% To server: {ClientPid, logoff}
%%% Reply: {messenger, logged_off}
%%%
%%% To server: {ClientPid, logoff}
%%% Reply: no reply
%%%
%%% To server: {ClientPid, message_to, ToName, Message} send a message
%%% Reply: {messenger, stop, you_are_not_logged_on} stops the client
%%% Reply: {messenger, receiver_not_found} no user with this name logged on
%%% Reply: {messenger, sent} Message has been sent (but no guarantee)
%%%
%%% To client: {message_from, Name, Message},
%%%
%%% Protocol between the "commands" and the client
%%% ----------------------------------------------
%%%
%%% Started: messenger:client(Server_Node, Name)
%%% To client: logoff
%%% To client: {message_to, ToName, Message}
%%%
%%% Configuration: change the server_node() function to return the
%%% name of the node where the messenger server runs

-module(messenger).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start_server/0, server/0]).

-export([logon/1, logoff/0, message/2]).

-export([client/2]).

%%
%% API Functions
%%



%%
%% Local Functions
%%


%% Change the function below to return the name of the node where the server messenger runs
server_node() ->
	'messenger@vhg-MOBL'.


%% This is the server process for the messenger
server()->
	process_flag(trap_exit,true),
	server([]).

%% The user list has the format [ {ClientPid1, Name1}, {ClientPid2, Name2}...... ]
server (User_List)->
	receive
		{From, logon, Name} ->
			io:format("Received logon from: ~p~n",[Name]),
			New_User_List = server_logon(From, Name, User_List),
			io:format("List is now: ~p ~n",[New_User_List]),
			server(New_User_List);
		{'EXIT', From, _} ->
			New_User_List = server_logoff( From, User_List),
			io:format("List is now: ~p ~n",[New_User_List]),
			server(New_User_List);
		{From, logoff} ->
			New_User_List = server_logoff( From, User_List),
			io:format("List is now: ~p ~n",[New_User_List]),
			server(New_User_List);
		{From, message_to, To, Message}->
			server_transfer(From, To, Message, User_List),
			server(User_List)
	end.


%% start the server 
start_server()->
	register(messenger, spawn(messenger, server, [])).

%% server adds new user to the user list
server_logon(From, Name, User_List) ->
	%%Check if logged on anywhere
	case lists:keymember(Name, 2, User_List) of
		true ->
			From ! {messenger, stop, user_exists_at_other_node};
		false ->
			From ! {messenger, logged_on},
			[{From,Name}| User_List]
	end.

%% server deletes a userfrom the user list
server_logoff(From, User_List)->
	lists:keydelete(From, 1, User_List).

		
%% Server transfers message between users
%% Check the userwho is logged on
server_transfer(From, To, Message, User_List) ->
	case lists:keysearch(From, 1, User_List) of
		false->
			From ! {messenger, stop, you_are_not_logged_on};
		{value,{From, Name}} ->
			%server_tranfer(From, Name, To, Messae, User_List),
			case lists:keysearch(To,2,User_List) of
				false ->
					From ! {messenger, stop, receiver_not_found};
				{value,{ToAddr, To}} ->
					ToAddr ! {message_from, Name, Message},
					From ! {messenger, sent}
			end
	end.


%% Client process which runs on each node
client(Server_Node, Name)->
	{messenger, Server_Node} ! {self(), logon, Name},
	await_result(),
	client(Server_Node).

client(Server_Node) ->
	receive
		logoff ->
			{messenger, Server_Node} ! {self(), logoff},
			exit(normal);
		{message_to, ToName, Message} ->
			{messenger, Server_Node} ! {self(), message_to, ToName, Message};
		{message_from, FromName, Message} ->
			io:format("~p: ~p~n",[FromName,Message])
	end,
	client(Server_Node).
	
%% Wait for a response from the server
await_result()->
	receive
		{messenger, stop, Why} ->
			io:format("~p~n",[Why]),
			exit(normal);
		{messenger, What} ->
			io:format("~p~n",[What])
	after 5000 ->
			io:format("No response from server~n",[]),
			exit(timeout)
	end.


%usage commands

logon(Name) ->
	case whereis(mess_client)of
		undefined ->
			register(mess_client, spawn(messenger, client, [server_node(), Name]));
		_ ->
			already_logged_on
	end.

logoff() ->
	mess_client ! logoff.
			
message(ToName, Message) ->
	case whereis(mess_client) of
		undefined ->
			not_logged_on;
		_ ->
			mess_client ! {message_to, ToName, Message},
			ok
	end.


