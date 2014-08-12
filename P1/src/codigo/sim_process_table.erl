% Representa un manejo muy sencillo de la accion de una Tabla de procesos
-module(sim_process_table).
-export([start/1]).

%
%
%
%
%
loop_process_table( _, P, P, Stats)->
    hard_drive ! {sim_exit, dict:store(process_table, Stats, dict:new())},
    exit(ok);
    
loop_process_table(Processes, Pfin, Ptot, Stats)->
  
  receive
    {agregar_proceso, Process = {Id, _, Vpags}} ->

        NewStats=sim_stat:sumar_all(Stats,[
          {peticiones,1},
          {sum_vpags, length(Vpags)}
        ]),                
        loop_process_table(dict:append(Id, Process, Processes), Pfin, 
                           Ptot, NewStats);
    {eliminar_proceso, Id} -> 

        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}, {atendidos, 1}]),                           
        loop_process_table(dict:erase(Id, Processes), Pfin+1, Ptot, NewStats); 
    {fail_creation, _}->  
      
        loop_process_table(Processes, Pfin+1, Ptot, Stats);     
    {actualizar_proceso, Process = {Id, _, _}} ->

        P1=dict:erase(Id, Processes),
        P2=dict:append(Id, Process, P1),
        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}]),                        
        loop_process_table(P2, Pfin, Ptot, NewStats);               
    {get_process, {Id, CPU}} -> 

        {ok,[{_, Size, Vpags}]} = dict:find(Id, Processes),  
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

    Stats = sim_stat:init_all(sim_stat:new(process_table),
            [{peticiones, 0}, {atendidos,0}, {sum_vpags, 0}, {totales,Ptot}]),    
    loop_process_table(dict:new(), 0, Ptot, Stats).
    
