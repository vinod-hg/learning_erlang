%% Author: vhg
%% Created: Mar 12, 2010
%% Description: TODO: Add description to sample
-module(sample).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([split_query/2, get_token/3, get_last_token/2]).

%%
%% API Functions
%%



%%
%% Local Functions
%%

split_query(Query,Rule)->
	SplitRules = string:tokens(Rule, "$()"),
	io:format("~n~p~n",[SplitRules]),
	{RulesRev, ParamNamesRev} = split(SplitRules,[],[]),
	Rules = lists:reverse(RulesRev),
	ParamNames = lists:reverse(ParamNamesRev),
	io:format("~p ~p~n",[Rules,ParamNames]),
	get_param(Query, Rules, ParamNames,[]).

split([],Rules,ParamNames) ->
	{Rules, ParamNames};
split([First|Rest],Rules,ParamNames) when Rest=:=[]->
	{[First|Rules], ParamNames};
split(List,Rules,ParamNames)->
	[Rule|Rest] = List,
	io:format("Rule:  ~p~n",[Rule]),
	[ParamName|Rest2] = Rest,
	io:format("Param: ~p~n",[ParamName]),
	split(Rest2,[Rule|Rules],[ParamName|ParamNames]).


get_param(QueryRule, [QueryRule], _, ParamList) ->
	ParamList;
get_param(Query, [RuleFirst|RuleRest], ParamNames, ParamList) ->	
	QueryFirst = string:substr(Query,1,string:len(RuleFirst)),	
	QueryRest = string:substr(Query, string:len(RuleFirst)+1),
	case string:equal(QueryFirst, RuleFirst) of
		true ->
			%copy the value till next occurance
			[RuleFirst1|_] = RuleRest, 
			SubString = string:sub_string(RuleFirst1, 1, 1),			
			Paramlength = string:str(QueryRest, SubString),
			%io:format(" ~p ~n",[Paramlength]),
			Param = string:substr(QueryRest, 1, Paramlength-1),
			NewQuery = string:substr(QueryRest, Paramlength),
			[ParamName| ParamRest] = ParamNames,
			NewparamList = [{ParamName, Param} | ParamList],
			get_param(NewQuery,RuleRest, ParamRest, NewparamList);
		false ->
			{error}
	end.
			

%%
%% The String is split into tokens with the delimiter (Delim) and the nth (Index) token is returned
%%
get_token(String, Delim, Index) ->
	SplitStrings = string:tokens(String, Delim),
	lists:nth(Index, SplitStrings).

get_last_token(String, Delim) ->
	SplitStrings = string:tokens(String, Delim),
	lists:last(SplitStrings).

	