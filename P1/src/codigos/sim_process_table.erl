-module(sim_process_table).
-export([start/1]).

%
%
%
%
%
loop_process_table(Processes, P, P, Stats)->
    hard_drive ! {sim_exit, dict:store(process_table, Stats, dict:new())},
   % io:format("SE ACABO TODO~n"),    
    exit(ok);
loop_process_table(Processes, Pfin, Ptot, Stats)->
T=now(),
  receive
    {agregar_proceso, Process = {Id, Size, Vpags}} ->
        %se agrega un proceso
        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1},{sum_vpags, length(Vpags)}]),                
        loop_process_table(dict:append(Id, Process, Processes), Pfin, Ptot, NewStats);
    {eliminar_proceso, Id} -> 
        %se elimina un proceso 
        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}, {atendidos, 1}]),                           
        loop_process_table(dict:erase(Id, Processes), Pfin+1, Ptot, NewStats); 
    {fail_creation,Id}->    
        loop_process_table(Processes, Pfin+1, Ptot, Stats);     
    {actualizar_proceso, Process = {Id, Size, Vpags}} ->
        %se actualiza un proceso
        P1=dict:erase(Id, Processes),
        P2=dict:append(Id, Process, P1),
        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}]),                        
        loop_process_table(P2, Pfin, Ptot, NewStats);               
    {get_process, {Id, CPU}} -> 
        %se elimina un proceso  
        {ok,[{Id1, Size, Vpags}]} = dict:find(Id, Processes),  
        kernel ! {ready_complete_process, {Id, Size, Vpags, CPU}},
        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}]),                        
        loop_process_table(Processes, Pfin, Ptot, NewStats)
  end.

%
%
%
%
%
start(Ptot) ->
    %io:format("Hola soy la tabla de procesos.~n"),
    Stats = sim_stat:init_all(sim_stat:new(process_table),
            [{peticiones, 0}, {atendidos,0}, {sum_vpags, 0}, {totales,Ptot}]),    
    loop_process_table(dict:new(), 0, Ptot, Stats).
    
