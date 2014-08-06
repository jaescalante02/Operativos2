-module(sim_stat).
-export([new/1,init/3, sumar/3, push/3, print/1, init_all/2]).


init_all(Stat, [])->Stat;
init_all(Stat, [{Key, IniValue}| L])->
    New_stat=init(Stat, Key, IniValue),
    init_all(New_stat, L).



init(Stat={Name, Dic}, Key, IniValue)->
  {Name, dict:store(Key, IniValue, Dic)}.


sumar(Stat={Name, Dic}, Key, Update)->
  {ok, Old} = dict:find(Key, Dic),
  New = Old + Update,  
  {Name, dict:store(Key, New, Dic)}.

push(Stat={Name, Dic}, Key, Update)->
  {ok, Old} = dict:find(Key, Dic),
  New = [Update | Old] ,  
  {Name, dict:store(Key, New, Dic)}.

print(Stat={Name, Dic})->
  io:format("~p: ~p~n", [Name, dict:to_list(Dic)]).

%
%
%
%
%
new(Name) ->
    {Name, dict:new()}.
