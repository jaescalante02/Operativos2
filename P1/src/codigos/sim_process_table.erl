-module(sim_process_table).
-export([start/1]).

%
%
%
%
%
loop_process_table(Processes, P, P, Stats)->
    %mensajito de sim_exit
    exit(ok);
loop_process_table(Processes, Pact, Ptot, Stats)->
T=now(),
  receive
    {agregar_proceso, Process = {Id, Size, Vpags}} ->
        %se agrega un proceso
        loop_process_table(dict:append(Id, Process, Processes), Pact, Ptot, Stats);
    {eliminar_proceso, Id} -> 
        %se elimina un proceso    
        loop_process_table(dict:erase(Id, Processes), Pact, Ptot, Stats); 
    {actualizar_proceso, Process = {Id, Size, Vpags}} ->
        %se actualiza un proceso
        P1=dict:erase(Id, Processes),
        P2=dict:append(Id, Process, P1),
        loop_process_table(P2, Pact, Ptot, Stats);               
    {get_process, {Id, CPU}} -> 
        %se elimina un proceso  
        {ok,[{Id1, Size, Vpags}]} = dict:find(Id, Processes),  
        kernel ! {ready_complete_process, {Id, Size, Vpags, CPU}},
        loop_process_table(Processes, Pact, Ptot, Stats)
  end.

%
%
%
%
%
start(Ptot) ->
    io:format("Hola soy la tabla de procesos.~n"),
    Stats = sim_stat:init_all(sim_stat:new(process_table),[{peticiones, 0}]),    
    loop_process_table(dict:new(), 0, Ptot, Stats).
    
