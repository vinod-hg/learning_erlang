%% Author: vhg
%% Created: Mar 3, 2010
%% Description: TODO: Add description to testing
-module(sequential).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([mul/2]).
-export([fact/1]).
-export([convert/1]).
-export([list_length/1]).

-export([format_temps/1]).

-export([list_max/1]).

-export([reverse/1]).

-export([format_temps2/1]).


%%
%% API Functions
%%


%%
%% Local Functions
%%

%mul
mul(X,Y) ->
	X*Y.

%factorial - more than 1 definition
fact(1) ->
	1;
fact(N) ->
	N * fact(N-1).



%conversion - Atoms/Tuples
convert({inch, I})->
	{centimeter, I/2.54};

convert({centimeter, C})->
	{inch, C*2.54}.


%find length - Lists
list_length([])->
	0;
list_length([_First|Rest])->
	1 + list_length(Rest).




%% Only this function is exported
format_temps([])->                        % No output for an empty list
    ok;
format_temps([City_Temp | Rest_Temp]) ->
    print_temp(convert_to_celsius(City_Temp)),
    format_temps(Rest_Temp).

convert_to_celsius({City, {c, Temp}}) ->  % No conversion needed
    {City, {c, Temp}};
convert_to_celsius({City, {f, Temp}}) ->  % Do the conversion
    {City, {c, (Temp - 32) * 5 / 9}}.

print_temp({City, {c, Temp}}) ->
    io:format("~-15w ~w c~n", [City, Temp]).



%% To find the maximum element in the list

list_max([Head|Rest])->
	list_max(Rest,Head).

list_max([],Max)->
	Max;

list_max([Head|Rest],Max) when Head > Max ->
	New_Max = Head,
	list_max(Rest,New_Max);

list_max([_Head|Rest],Max)->
	list_max(Rest,Max).


%% Reversing a list

reverse(List)->			%reverse([Head|Rest])->
	reverse(List,[]).	%	reverse(Rest,Head).	Gives the output as [3,2|1] instead of [3,2,1]

reverse([],Reversed_List)->
	Reversed_List;
reverse([Head|Rest],Reversed_List)->
	reverse(Rest,[Head|Reversed_List]).



% Format the temperature
format_temps2(List_of_cities) ->
	Converted_list = convert_list_to_c (List_of_cities),
	print_temps(Converted_list),
	{Min_city,Max_city} = find_min_max(Converted_list),
	print_min_max(Min_city,Max_city).

convert_list_to_c([{Name,{f, Temp}} |Rest])->
	Converted_City = {Name,{c, (Temp-32)*5/9}},
	[Converted_City|convert_list_to_c(Rest)];
convert_list_to_c([C_city|Rest])->
	[C_city|convert_list_to_c(Rest)];	
convert_list_to_c([])->
	[].

print_temps([{Name,{c,Temp}}|Rest])->
	io:format("~15w ~w c ~n",[Name,Temp]),	%~15w .. if applied on digits and digit count is more than 15 
											%then **** appears. We should use trunc function
	print_temps(Rest);
print_temps([])->
	ok.


find_min_max([City|Rest])->
	find_min_max(Rest,City,City).

find_min_max([City = {_,{c,Temp}}| Rest],
			 MinCity = {_,{c,MinTemp}},
			 MaxCity = {_,{c,MaxTemp}})->
	if
		Temp < MinTemp ->
			NewMinCity = City;
		true ->
			NewMinCity = MinCity
	end,
	if
		Temp > MaxTemp ->
			NewMaxCity = City;
		true ->
			NewMaxCity = MaxCity
	end,
	find_min_max(Rest,NewMinCity,NewMaxCity);

find_min_max([],MinCity,MaxCity) ->
	{MinCity,MaxCity}.
	

print_min_max({MinName,{c,TempMin}},{MaxName,{c,TempMax}})->
	io:format("Minimum Temperature is ~w c in ~w~n",[TempMin,MinName]),
	io:format("Maximum Temperature is ~w c in ~w",[TempMax,MaxName]).
	