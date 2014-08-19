-module(script).
-export([main/1]).
main([K])->
	io:format("~p~n",[K]).
