%%% API of the server 

-module(usr).
-include("usr.hrl").
-compile(export_all).

-define(TIMEOUT, 30000).

%%% Exported client functions
%%% API of the operation and maintenance

start() ->
	start("UsrTabFile").

start(FileName) ->
	register(?MODULE, spawn(?MODULE, init, [FileName, self()])),
	receive started -> ok after ?TIMEOUT -> { error, starting } end.

stop() ->
	call(stop).

%%% API of the service for users

add_usr(PhoneNum, CustId, Plan) when Plan == prepay; Plan == postpay ->
	call({ add_usr, PhoneNum, CustId, Plan }).

delete_usr(CustId) ->
	call({ delete_usr, CustId }).

set_service(CustId, Service, Flag) when Flag == true; Flag == false ->
	call({ set_service, CustId, Service, Flag }).

set_status(CustId, Status) when Status == enabled; Status == disabled ->
	call({ set_status, CustId, Status }).

delete_disabled() ->
	call(delete_disabled).

lookup_id(CustId) ->
	usr_db:lookup_id(CustId).

%%% API of the system applications

lookup_msisdn(PhoneNo) ->
	usr_db:lookup_msisdn(PhoneNo).

service_flag(PhoneNo, Service) ->
	case usr_db:lookup_msisdn(PhoneNo) of
		{ ok, #usr{ services = Services, status = enabled } } ->
			lists:member(Service, Services);
		{ ok, #usr{ status = disabled }} ->
			{ error, disabled };
		{ error, Reason } ->
			{ error, Reason }
	end.

%%% Sending messages

call(Request) ->
	Ref = make_ref(),
	?MODULE! { request, { self(), Ref }, Request },
	receive 
		{ reply, Ref, Reply } -> Reply
	after 
		?TIMEOUT -> { error, timeout }
	end.

reply({ From, Ref }, Reply ) ->
	From ! { reply, Ref, Reply }.	

%%% Internal service functions

init(FileName, Pid) ->
	usr_db:create_tables(FileName),
	usr_db:restore_backup(),
	Pid ! started,
	loop().

loop() ->
	receive 
		{ request, From, stop } ->
			reply(From, usr_db:close_tables());
		{ request, From, Request } ->
			Reply = request(Request),
			reply(From, Reply),
			loop()
	end.

%%% Processing of client requests

request({ add_usr, PhoneNo, CustId, Plan }) ->
	usr_db:add_usr(#usr{ msisdn = PhoneNo, id = CustId, plan = Plan });

request({ delete_usr, CustId }) ->
	usr_db:delete_usr(CustId);

request({ set_service, CustId, Service, Flag }) ->
	case usr_db:lookup_id(CustId) of
		{ ok, Usr } ->
			Services = lists:delete(Service, Usr#usr.services),
			NewServices = case Flag of 
											true  -> [Service | Services];
											false -> Services
										end,
			usr_db:update_usr(Usr#usr{ services = NewServices });
		{ error, instance } ->
			{ error, instance }
	end;

request({ set_status, CustId, Status }) ->
	case usr_db:lookup_id(CustId) of
		{ ok, Usr } ->
			usr_db:update_usr(Usr#usr{ status = Status });
		{ error, instance } ->
			{ error, instance }
	end;

request(delete_disabled) ->
	usr_db:delete_disabled().





