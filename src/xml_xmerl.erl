%% Author: vhg
%% Created: May 27, 2010
%% Description: TODO: Add description to xml_xmerl
-module(xml_xmerl).

%%
%% Include files
%%

-include_lib("xmerl.hrl").

%%
%% Exported Functions
%%
-export([create_xml/0,
		 pkt_to_xml/0,
		 pkt_to_xml1/0,
		 pkt_to_xml3/0,
		 pkt2xml/1,
		 complex_pkt2/0,
		 pkt2xml_test/0,
		 pkt2str/0]).


-record(packet, {
					req_protocol = "this",	% protocol - https, this means local(same) system
					req_host = "localhost",	% host - ip addr of remote system, localhost for local(same) system 
					req_port = "7777",		% port - port of remote system, default is 7777
					req_resource = "",		% Query string. Default empty
					req_data_fmt = "flat",	% flat/ tree, default flat
					req_operation,			% get, set
					resp_status = "0",
					resp_data_fmt = "flat",		% flat/ tree
					
					data = []				% response data - list of {XPATH, value)}
				}
		).


%%
%% API Functions
%%



%%
%% Local Functions
%%


create_xml() ->
	Data = { bike, 
			  [
			   {year,"2003"},{color,"black"},{condition,"new"}
			  ],
			  [
			   {name,[{manufacturer,["Harley Davidsson"]},
					  {brandName,["XL1200C"]},
					  {additionalName,["Sportster"]}]},
			   {engine, ["V-engine, 2-cylinders, 1200 cc"]},
			   {kind,["custom"]},
			   {drive,["belt"]}
			  ]
		   },
	
	
	%{RootEl,Misc}=xmerl_scan:file('motorcycles.xml'),
	%#xmlElement{content=Content} = RootEl,
	Content = "",
	NewContent=Content++lists:flatten([Data]),
	io:format("NewContent: ~p~n",[NewContent]),
	NewRootEl=#xmlElement{content=NewContent},
	io:format("NewRootEl: ~p~n",[NewRootEl]),
	{ok,IOF}=file:open('new_motorcycles.xml',[write]),
	Export=xmerl:export_simple([NewRootEl],xmerl_xml),
	io:format(IOF,"~s~n",[lists:flatten(Export)]).


simple_xml() -> 
	list_to_binary(
"<?xml version=\"1.0\"?>
<responses xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">
	<response>
		<resource>
			<name>/SYSTEM/PLATFORM/HARDDISK/HEALTH_CONFIG/CRITICAL_LIMIT</name>
			<data xsi:type=\"flat\">0.9</data>
		</resource>
	</response>
</responses>
").

simple_pkt1() ->
	#packet{
			req_resource = "/SYSTEM/BMC/LAN[1]",
			req_data_fmt = "flat",
			req_operation = "get",
			resp_data_fmt = "flat",
			data = [{list_to_binary("/SYSTEM/BMC/LAN[1]/IP"), list_to_binary("10.223.23.2")},
					{list_to_binary("/SYSTEM/BMC/LAN[1]/GATEWAY"), list_to_binary("10.212.21.2")},
					{list_to_binary("/SYSTEM/BMC/LAN[1]/MAC"), list_to_binary("01:02:03:04:05:06")}
		  			]
			}.



%% ==================================================================

pkt_to_xml2() ->
	Packet = simple_pkt(),
	ResData = get_data1("tree", Packet#packet.data),
	NewContent=lists:flatten([ResData]),
	NewRootEl=#xmlElement{name = responses, attributes = [#xmlAttribute{name = list_to_atom("xmlns:xsi"),value = "http://www.w3.org/2001/XMLSchema-instance\\"}], content = NewContent, elementdef = responses},
	
	Export=xmerl:export_simple([NewRootEl],xmerl_xml),
	write_to_file("~s~n",[lists:flatten(Export)]).


	

get_data1("tree", Data) ->
	Data_List = lists:foldl(fun({Key,Value}, DataAcc) ->
									SplitStrings = string:tokens(binary_to_list(Key), "/,[]"),
									[lists:append(SplitStrings, binary_to_list(Value))| DataAcc]
									%[{SplitStrings, []}| DataAcc]
							 end, [], Data),
	
	write_to_file("~p~n",[(Data_List)]),
	%creat_group(Data_List),
	
	[{Key,Value}| _Rest] = Data,
	
	
	
	SplitStrings = string:tokens(binary_to_list(Key), "/,[]"),
	write_to_file("~p~n",[(SplitStrings)]),
	
	ResData = lists:foldr(fun(ResourceKey, DataAcc) -> 
									 [{list_to_atom(ResourceKey), DataAcc}]
							 end, [binary_to_list(Value)], SplitStrings),

	write_to_file("~p~n",[(ResData)]),
	ResData.
	%SplitStrings
	
example()->
	
	[{'SYSTEM',
	  [{'BMC',
		[{'LAN',
		  [{'1',
			[{'IP',"10.223.23.2"}]
		   }]
		 }]
	   }]
	 }]
.


init_file() ->
	{ok,IOF}=file:open('packet_tree.xml',[write]),
	io:format(IOF,"~n",[]),
	file:close(IOF).
write_to_file(Message,Parametes) ->
	{ok,IOF}=file:open('packet_tree.xml',[append]),
	io:format(IOF,Message,Parametes),
	file:close(IOF).
	

%% ==================================================================


create_struct([], {KeyData, PrevElements}, New_Data_List) ->
	write_to_file("KeyData: ~p~n Prev: ~p~n New: ~p~n",[KeyData, PrevElements, New_Data_List]),
	{PrevElements, New_Data_List};	
create_struct( [ [DataFirst | RestElements] | RestData] , {KeyData, PrevElements}, New_Data_List)->
	write_to_file("KeyData1: ~p~n Prev1: ~p~n New1: ~p~n",[KeyData, PrevElements, New_Data_List]),
	write_to_file("DataFirst1: ~p~n RestElements1: ~p~n RestData1: ~p~n",[DataFirst, RestElements, RestData]),
	if DataFirst =:= KeyData ->
		   NewElem = [ RestElements | [PrevElements]],
		   create_struct(RestData, {KeyData, NewElem}, New_Data_List);
	   
	   true ->
		   create_struct(RestData, {KeyData, PrevElements}, [[DataFirst | RestElements] | New_Data_List])
	end.


create_inner([]) ->
	[];
create_inner([[Key, Value]]) ->
	%write_to_file("Value1: ~p~n",[Value]),
	[{list_to_atom(Key), [Value]}];
create_inner([Value]) ->
	%write_to_file("Value: ~p~n",[Value]),
	[Value];
create_inner([ [ElemKey| InnerElement]| RestElements] = _Elements) ->
	{InnerElements, New_Elements} = create_struct( RestElements , {ElemKey, InnerElement}, []),
	
	write_to_file("Key:~p Elements: ~p ~nNew :~p~n",[ElemKey, InnerElements,New_Elements]),
	%write_to_file("DataFirst1: ~p~n RestElements1: ~p~n RestData1: ~p~n",[DataFirst, RestElements, RestData]),
	
	[{list_to_atom(ElemKey), create_inner(InnerElements)}| create_inner(New_Elements) ].



pkt_to_xml1() ->
	Packet = complex_pkt(),
	Data = Packet#packet.data,
	
	Data_List = lists:foldl(fun({Key,Value}, DataAcc) ->
									SplitStrings = string:tokens(binary_to_list(Key), "/,[]"),
									[lists:append(SplitStrings, [binary_to_list(Value)])| DataAcc]
									%[SplitStrings| DataAcc]
							 end, [], Data),
	
	%write_to_file("~p~n",[(Data_List)]),
	ResData = create_inner(Data_List),
	%write_to_file("~p~n",[(ResData)]),

	NewContent=lists:flatten([ResData]),
	NewRootEl=#xmlElement{name = responses, attributes = [#xmlAttribute{name = list_to_atom("xmlns:xsi"),value = "http://www.w3.org/2001/XMLSchema-instance\\"}], content = NewContent, elementdef = responses},
	
	Export=xmerl:export_simple([NewRootEl],xmerl_xml),
	write_to_file("~s~n",[lists:flatten(Export)]).


simple_pkt() ->
	#packet{
			req_resource = "/SYSTEM/BMC/LAN[1]",
			req_data_fmt = "flat",
			req_operation = "get",
			resp_data_fmt = "flat",
			data = [{list_to_binary("/SYSTEM/BMC/LAN[1]/IP"), list_to_binary("123")},
					%{list_to_binary("/SYSTEM/BMC/LAN[1]/GATEWAY"), list_to_binary("456")},
					{list_to_binary("/SYSTEM/BMC/LAN[1]/MAC"), list_to_binary("789")}
		  			]
			}.

	
complex_pkt() ->
#packet{req_resource = "/SYSTEM/PLATFORM/TEMPERATURE/SENSORS",
			req_data_fmt = "flat",
			req_operation = "get",
			resp_data_fmt = "tree",
			data =
                                      [{<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/SENSOR_NUM">>,
                                        <<"106">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/INTERPRET_SENSOR_UNITS">>,
                                        <<>>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/NAME">>,
                                        <<"IOH Thermal Trip">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/INTERPRET_SENSOR_VALUE">>,
                                        <<"STATE_DEASSERTED">>}]
	   }.
									   




complex_pkt2() ->
	#packet{req_resource = "/SYSTEM/PLATFORM/TEMPERATURE/SENSORS",
			req_data_fmt = "flat",
			req_operation = "get",
			resp_data_fmt = "tree",
			data =
                                      [{<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/SENSOR_NUM">>,
                                        <<"106">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/INTERPRET_SENSOR_UNITS">>,
                                        <<>>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/NAME">>,
                                        <<"IOH Thermal Trip">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[11]/INTERPRET_SENSOR_VALUE">>,
                                        <<"STATE_DEASSERTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/SENSOR_NUM">>,
                                        <<"103">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/INTERPRET_SENSOR_UNITS">>,
                                        <<>>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/NAME">>,
                                        <<"P2 VRD Hot">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[10]/INTERPRET_SENSOR_VALUE">>,
                                        <<"LIMIT_NOT_EXCEEDED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/SENSOR_NUM">>,
                                        <<"102">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/NAME">>,
                                        <<"P1 VRD Hot">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[9]/INTERPRET_SENSOR_VALUE">>,
                                        <<"LIMIT_NOT_EXCEEDED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/SENSOR_NUM">>,
                                        <<"101">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"11.700000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"19.500000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_SENSOR_UNITS">>,
                                        <<"% ">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/NAME">>,
                                        <<"P2 Therm Ctrl %">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[8]/INTERPRET_SENSOR_VALUE">>,
                                        <<"0.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/SENSOR_NUM">>,
                                        <<"100">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"11.700000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"19.500000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_SENSOR_UNITS">>,
                                        <<"% ">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/NAME">>,
                                        <<"P1 Therm Ctrl %">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[7]/INTERPRET_SENSOR_VALUE">>,
                                        <<"0.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/SENSOR_NUM">>,
                                        <<"99">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/NAME">>,
                                        <<"P2 Therm Margin">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[6]/INTERPRET_SENSOR_VALUE">>,
                                        <<"-54.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/SENSOR_NUM">>,
                                        <<"98">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/NAME">>,
                                        <<"P1 Therm Margin">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[5]/INTERPRET_SENSOR_VALUE">>,
                                        <<"-57.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/SENSOR_NUM">>,
                                        <<"87">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/HEALTH">>,
                                        <<"Unavailable">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"55.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"60.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/NAME">>,
                                        <<"PS2 Temperature">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[4]/INTERPRET_SENSOR_VALUE">>,
                                        <<"READING_UNAVAILABLE">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/SENSOR_NUM">>,
                                        <<"36">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/HEALTH">>,
                                        <<"Unavailable">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"5.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"10.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/NAME">>,
                                        <<"Mem P2 Thrm Mrgn">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[3]/INTERPRET_SENSOR_VALUE">>,
                                        <<"READING_UNAVAILABLE">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/SENSOR_NUM">>,
                                        <<"35">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"5.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"10.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/NAME">>,
                                        <<"Mem P1 Thrm Mrgn">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[2]/INTERPRET_SENSOR_VALUE">>,
                                        <<"-42.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/SENSOR_NUM">>,
                                        <<"34">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"5.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"10.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/NAME">>,
                                        <<"IOH Therm Margin">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[1]/INTERPRET_SENSOR_VALUE">>,
                                        <<"-64.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/OWNER">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/LUN">>,
                                        <<"0">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/SENSOR_NUM">>,
                                        <<"32">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/SENSOR_TYPE">>,
                                        <<"1">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/HEALTH">>,
                                        <<"Healthy">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_LOWER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_LOWER_NONCRITICAL">>,
                                        <<"10.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_LOWER_CRITICAL">>,
                                        <<"5.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_UPPER_NONRECOVERABLE">>,
                                        <<"NOT SUPPORTED">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_UPPER_NONCRITICAL">>,
                                        <<"77.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_UPPER_CRITICAL">>,
                                        <<"84.000000">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_SENSOR_UNITS">>,
                                        <<"Degrees Celsius">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/NAME">>,
                                        <<"Baseboard Temp">>},
                                       {<<"/SYSTEM/PLATFORM/TEMPERATURE/SENSORS/SENSOR[0]/INTERPRET_SENSOR_VALUE">>,
                                        <<"46.000000">>}]
	   }.

%% ==================================================================
update_parents1([]) ->
	ok;
update_parents1([_Name | XPathList] = FullXPath) ->
	case ets:lookup(temp, XPathList) of
		[] ->
			update_parents1(XPathList);
		_ ->
			ok
	end,
	ets:insert(temp, {XPathList, FullXPath}).
update_table1([_Name | XPathList] = FullXPath, Value) ->
	case ets:lookup(temp, XPathList) of
		[] ->
			update_parents1(XPathList);
		_ ->
			ok
	end,
	ets:insert(temp, {XPathList, {FullXPath, Value}}).  

convert_1(Key,Value)->
	SplitStrings = string:tokens(binary_to_list(Key), "/"),
	%Reversed = lists:reverse(SplitStrings),	
	Reversed = lists:foldl(fun(String, ReversedAtomList) -> 
								   case string:str(String, "[") of
									   0 -> [list_to_atom(String)| ReversedAtomList];
									   _ -> [String | ReversedAtomList]
								   end
						   end,
						   [], SplitStrings),
	update_table1(Reversed, binary_to_list(Value)),
	ok.	

get_data2("tree", Data) ->
	ets:new(temp, [named_table, bag]),
	lists:foreach(fun({Key,Value}) -> convert_1(Key, Value) end, Data),
	convert_xml1().


convert_xml1() ->
	case ets:lookup(temp, []) of
		[{[],Object}] ->
			[Key] = Object,
			[{Key, convert_1(Object)}];
		[] ->
			ok
	end.
  
convert_2([]) ->
	[];
convert_2([{_, {[Name| _XPath], []} }| Rest]) when is_atom(Name)->
	[{Name, []} | convert_2(Rest)];
convert_2([{_, {[Name| _XPath], []} }| Rest]) ->
	[{list_to_atom(Name), []} | convert_2(Rest)];

convert_2([{_, {[Name| _XPath], Value} }| Rest]) when is_atom(Name)->
	[{Name, [Value]} | convert_2(Rest)];
convert_2([{_, {[Name| _XPath], Value} }| Rest]) ->
	[{list_to_atom(Name), [Value]} | convert_2(Rest)];

convert_2([{_,[Key| _RestPath] = Object}| []]) when is_atom(Key)->
	[{Key, convert_1(Object)}];
convert_2([{_,[Key| _RestPath] = Object}| Rest]) ->
	[{list_to_atom(Key), convert_1(Object)} | convert_2(Rest)].
	

convert_1(XPathList) ->
	case ets:lookup(temp, XPathList) of
		[] ->
			error;
		Objects ->
			convert_2(Objects)			
	end.	

	
pkt_to_xml3() ->
	
	Packet = complex_pkt2(),
	Data = Packet#packet.data,

	%dict:new()
	ets:new(temp, [named_table, bag]),
	lists:foreach(fun({Key,Value}) -> convert_1(Key, Value) end, Data),
	
	Data_List = ets:tab2list(temp),
	Xmerl = convert_xml1(),
	%write_to_file("~p~n",[(Data_List)]),
	write_to_file("~p~n",[Xmerl]),
	
	NewContent=lists:flatten([Xmerl]),
	NewRootEl=#xmlElement{name = responses, attributes = [#xmlAttribute{name = list_to_atom("xmlns:xsi"),value = "http://www.w3.org/2001/XMLSchema-instance\\"}], content = NewContent, elementdef = responses},
	
	Export=xmerl:export_simple([NewRootEl],xmerl_xml),
	write_to_file("~s~n",[lists:flatten(Export)]).
	


%% ==================================================================
%% ==================================================================

%Foreach
%1. Split
%2. Reverse
%3. For each
%  search FullList-1 = NewList
%  	Found - insert
%   else search NewList

% packet data to dict
update_parents([], Dict) ->
	Dict;
update_parents([_Name | XPathList] = FullXPath, Dict) ->
	try Values = dict:fetch(XPathList, Dict),	
		dict:store(XPathList, [FullXPath | Values], Dict)
	catch _:_ -> 
		NewDict = update_parents(XPathList, Dict),
		dict:store(XPathList, [FullXPath], NewDict)
	end.

update_table([_Name | XPathList] = FullXPath, Value, Dict) ->
	try Values = dict:fetch(XPathList, Dict),
		dict:store(XPathList, [{FullXPath, Value}|Values], Dict)
	catch _:_ -> 
		NewDict = update_parents(XPathList, Dict),
		dict:store(XPathList, [{FullXPath, Value}], NewDict)
	end.

convert(Key, Value, Dict)->
	SplitStrings = string:tokens(binary_to_list(Key), "/"),
	%Reversed = lists:reverse(SplitStrings),	
	Reversed = lists:foldl(fun(String, ReversedAtomList) -> 
								   case string:str(String, "[") of
									   0 -> [list_to_atom(String)| ReversedAtomList];
									   _ -> [String | ReversedAtomList]
								   end
						   end,
						   [], SplitStrings),
	update_table(Reversed, binary_to_list(Value), Dict).

% Dict to xmerl struct
convert2struct([], _Dict)->
	[];

convert2struct([{[ElemName | _ElemParentXPath], Value} | SiblingsXPaths], Dict) when is_atom(ElemName)->
	[{ElemName, [Value]} | convert2struct(SiblingsXPaths, Dict)];
convert2struct([{[Element | _ElemParentXPath], Value} | SiblingsXPaths], Dict) ->
	[ElemName , Id] = string:tokens(Element, "[]"),	
	[{list_to_atom(ElemName), [{id, Id}], [Value]} | convert2struct(SiblingsXPaths, Dict)];

convert2struct([[Element | _ParentXPath] = FullXPath | SiblingsXPaths], Dict) when is_atom(Element)->
	try ChildXPaths = dict:fetch(FullXPath, Dict),
		[{Element, convert2struct(ChildXPaths, Dict)} | convert2struct(SiblingsXPaths, Dict)]
	catch _:_ -> 
		error
	end;
convert2struct([[Element | _ParentXPath] = FullXPath | SiblingsXPaths], Dict)  ->
	try ChildXPaths = dict:fetch(FullXPath, Dict),
		[ElemName , Id] = string:tokens(Element, "[]"),	
		[{list_to_atom(ElemName), [{id, Id}], convert2struct(ChildXPaths, Dict)} | convert2struct(SiblingsXPaths, Dict)]
	catch _:_ -> 
		error
	end.


get_data("tree", Data) ->
	Dictionary = lists:foldl(fun({Key,Value}, DictAcc) -> 
									 convert(Key, Value, DictAcc) 
							 end, dict:new(), Data),
	try [[Root]] = RootXPath = dict:fetch([], Dictionary),
		[{Root, convert2struct(RootXPath, Dictionary)}]
	catch _:_ -> 
		error
	end;

get_data("flat", Data) ->
	 lists:foldl(fun({Key,Value}, DataAcc) -> 
									 [{list_to_atom(binary_to_list(Key)), [binary_to_list(Value)]}| DataAcc]
							 end, [], Data).

pkt_to_data(Packet) ->
	PacketData = get_data(Packet#packet.resp_data_fmt, Packet#packet.data),
	_Data = { response,
			  [ {resource,
				[ {name, [Packet#packet.req_resource]},
				  {data, [{list_to_atom("xsi:type"), Packet#packet.resp_data_fmt}], PacketData}
				]}
			  ]
		   }.


pkt2xml([FirstPacket | _Rest] = Packets) ->
	% Go through each packet in the list and get the responses
	Responses = lists:foldl(fun(Packet, Resps) ->
									[pkt_to_data(Packet)| Resps]
							end, [], Packets),
	XmlStruct = [{hash,
				  [{node,
					[{ip, [FirstPacket#packet.req_host]},
					 {port, [FirstPacket#packet.req_port]},
					 {protocol, [FirstPacket#packet.req_protocol]}
					]},
				   {responses, Responses}
				  ]}
				],
	
	
	XmlRoot = #xmlElement{name = list, 	% Root element name
						  attributes = [#xmlAttribute{name = list_to_atom("xmlns:xsi"),
													  value = "http://www.w3.org/2001/XMLSchema-instance\\"}], 
						  content = lists:flatten([XmlStruct]),
						  elementdef = responses},
	lists:flatten(xmerl:export_simple([XmlRoot],xmerl_xml)).

	


pkt2xml_test() ->
	PacketXml = pkt2xml([complex_pkt2()] ),
	
	{ok,IOF}=file:open('packet.xml',[write]),
	io:format(IOF,"~s~n",[PacketXml]).

pkt_to_xml() ->
	init_file(),
	%Packet = simple_pkt(),
	%Packets = [Packet#packet{resp_data_fmt = "tree"}],
	Packets = [complex_pkt2()],
	%write_to_file("Data: ~p~n~n", [Packets]),
	Data = lists:foldl(fun(Packet, Resps) ->
									[pkt_to_data(Packet)| Resps]
							end, [], Packets),
	NewContent=lists:flatten([[Data]]),
	%write_to_file("~p~n",[Data]),
	NewRootEl=#xmlElement{name = responses, attributes = [#xmlAttribute{name = list_to_atom("xmlns:xsi"),value = "http://www.w3.org/2001/XMLSchema-instance\\"}], content = NewContent},
	{ok,IOF}=file:open('packet.xml',[write]),
	Export=xmerl:export_simple([NewRootEl],xmerl_xml),
	io:format(IOF,"~s~n",[lists:flatten(Export)]).


%% ==================================================================
%%  packet to json string
%% ==================================================================
%% ==================================================================
%% xml generator
%% ==================================================================

% packet data to dict
update_parents1([], Dict) ->
	Dict;
update_parents1([_Name | XPathList] = FullXPath, Dict) ->
	try Values = dict:fetch(XPathList, Dict),	
		dict:store(XPathList, [FullXPath | Values], Dict)
	catch _:_ -> 
		NewDict = update_parents1(XPathList, Dict),
		dict:store(XPathList, [FullXPath], NewDict)
	end.

%%  search FullList-1 = XPathList
%%  	Found - insert
%%   else search NewList
update_table1([_Name | XPathList] = FullXPath, Value, Dict) ->
	try Values = dict:fetch(XPathList, Dict),
		dict:store(XPathList, [{FullXPath, Value}|Values], Dict)
	catch _:_ -> 
		NewDict = update_parents1(XPathList, Dict),
		dict:store(XPathList, [{FullXPath, Value}], NewDict)
	end.

%%Foreach
%% 1. Split
%% 2. Reverse
%% 3. For each
convert1(Key, Value, Dict)->
	SplitStrings = string:tokens(binary_to_list(Key), "/"),
	Reversed = lists:reverse(SplitStrings),	
	
	update_table1(Reversed, binary_to_list(Value), Dict).

% Dict to xmerl struct
convert2struct1([], _Dict, _Count)->
	[];
convert2struct1([{[ElemName | _ElemParentXPath], Value}], _Dict, true)->
	"\"" ++ ElemName ++ "\":\"" ++ Value ++ "\"]";
convert2struct1([{[ElemName | _ElemParentXPath], Value}], _Dict, false)->
	"\"" ++ ElemName ++ "\":\"" ++ Value;
convert2struct1([{[ElemName | _ElemParentXPath], Value} | SiblingsXPaths], Dict, false)->
	"[\"" ++ ElemName ++ "\":\"" ++ Value ++ "\"," ++ convert2struct1(SiblingsXPaths, Dict, true);
convert2struct1([{[ElemName | _ElemParentXPath], Value} | SiblingsXPaths], Dict, true)->
	"\"" ++ ElemName ++ "\":\"" ++ Value ++ "\"," ++ convert2struct1(SiblingsXPaths, Dict, true);

convert2struct1([[Element | _ParentXPath] = FullXPath | []], Dict, _Count)->
	try ChildXPaths = dict:fetch(FullXPath, Dict),
		"\"" ++ Element ++ "\":{" ++ convert2struct1(ChildXPaths, Dict, _Count) ++"}"
	catch Type:Error -> 
		write_to_file("Error: ~p~n",[{Type,Error}]),
		error
	end;
convert2struct1([[Element | _ParentXPath] = FullXPath | SiblingsXPaths], Dict, _Count)->
	try ChildXPaths = dict:fetch(FullXPath, Dict),
		"\"" ++ Element ++ "\":{" ++ convert2struct1(ChildXPaths, Dict, _Count) ++"}," ++ convert2struct1(SiblingsXPaths, Dict, _Count)
	catch Type:Error -> 
		write_to_file("Error: ~p~n",[{Type,Error}]),
		error
	end.


get_data_1("flat", Data) ->
	lists:foldl(fun({Key,Value}, DataAcc) ->
						[{resource,
						  [{name, [binary_to_list(Key)]},
						   {data, [binary_to_list(Value)]}
						  ]
						 } | DataAcc]
				end, [], Data);
get_data_1("tree", Data) ->
	Dictionary = lists:foldl(fun({Key,Value}, DictAcc) -> 
									 convert1(Key, Value, DictAcc) 
							 end, dict:new(), Data),
	write_to_file("Dict: ~p~n",[Dictionary]),
	try RootXPath = dict:fetch([], Dictionary),
		convert2struct1(RootXPath, Dictionary, false)
	catch _:_ -> 
		error
	end.


add_escapes(String) -> lists:flatmap( fun(Char) ->
																case(Char) of
																	$\n -> "\\n";
																	$\r -> "\\r";
																	_ -> [Char]
																end
															end,
															String).
serialize_data(Data) -> string:join(lists:map( fun({Key, Value}) ->
													"\"" ++ add_escapes(binary_to_list(Key))
													++"\":\""  ++ add_escapes(binary_to_list(Value))
													++ "\""
												  end,
												  Data), ",").
					  
pkt2str() -> 
	init_file(),
	Pkt = complex_pkt(),
	Json = list_to_binary(
								"{\"packet\":{\"req_protocol\":\"" ++ add_escapes(Pkt#packet.req_protocol) 
							  ++ "\",\"req_host\":\"" ++ add_escapes(Pkt#packet.req_host) 
							  ++ "\",\"req_port\":\"" ++ add_escapes(Pkt#packet.req_port) 
							  ++ "\",\"req_resource\":\"" ++ add_escapes(Pkt#packet.req_resource) 
							  ++ "\",\"req_data_fmt\":\"" ++ add_escapes(Pkt#packet.req_data_fmt) 
							  ++ "\",\"req_operation\":\"" ++ add_escapes(Pkt#packet.req_operation) 
							  ++ "\",\"resp_status\":\"" ++ add_escapes(Pkt#packet.resp_status) 
							  ++ "\",\"resp_data_fmt\":\"" ++ add_escapes(Pkt#packet.resp_data_fmt) 
							  ++ "\",\"data\":{" ++ get_data_1("tree", Pkt#packet.data)
							  ++ "}}}"
						  ),
	write_to_file("Final: ~p~n",[Json]).						  



