-module(usr_sup).
-compile(export_all).

-behaviour(supervisor).

start_link() ->
	supervisor:start_link({ local, ?MODULE }, ?MODULE, []).

init(FileName) ->
	UsrChild = { usr_otp, { usr_otp, start_link, [] },
							 permanent, 2000, worker, [usr_otp, usr_db] },
	{ ok, {{ one_for_all, 1, 1}, [UsrChild] }}.