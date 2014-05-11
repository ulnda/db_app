-module(usr_app).
-compile(export_all).

-behaviour(application).

start(_Type, StartArgs) ->
	usr_sup:start_link().

stop(_State) ->
	ok.