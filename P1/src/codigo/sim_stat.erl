% Clase stat para facilitar el manejo de informacion de manera generica.
-module(sim_stat).
-export([new/1,init/3, sumar/3, push/3, print/1, init_all/2,
        sumar_all/2, push_all/2]).

%
%
%
%
%
init_all(Stat, [])->Stat;
init_all(Stat, [{Key, IniValue}| L])->
    New_stat=init(Stat, Key, IniValue),
    init_all(New_stat, L).

%
%
%
%
%
init({Name, Dic}, Key, IniValue)->
  {Name, dict:store(Key, IniValue, Dic)}.

%
%
%
%
%
sumar_all(Stat, [])->Stat;
sumar_all(Stat, [{Key, UpdValue}| L])->
    New_stat=sumar(Stat, Key, UpdValue),
    sumar_all(New_stat, L).


%
%
%
%
%
sumar({Name, Dic}, Key, Update)->
  {ok, Old} = dict:find(Key, Dic),
  New = Old + Update,  
  {Name, dict:store(Key, New, Dic)}.


%
%
%
%
%
push_all(Stat, [])->Stat;
push_all(Stat, [{Key, UpdValue}| L])->
    New_stat=push(Stat, Key, UpdValue),
    push_all(New_stat, L).


%
%
%
%
%
push({Name, Dic}, Key, Update)->
  {ok, Old} = dict:find(Key, Dic),
  New = [Update | Old] ,  
  {Name, dict:store(Key, New, Dic)}.


%
%
%
%
%
print({Name, Dic})->
  io:format("~p: ~p~n", [Name, dict:to_list(Dic)]).

%
%
%
%
%
new(Name) ->
    {Name, dict:new()}.
