-module(sim_hard_drive).
-export([start/0]).

%
%
%
%
%
loop_hard_drive(Stats)->
  receive
    {cargar_process, {Id, Size, Npags}} ->
        Time=now(),
        %enviar mensaje a kernel con lista [0..Npags-1] proceso_cargado
        kernel ! {proceso_cargado, {Id, Size, Npags, lists:seq(0,Size-1)} },
        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1},{tiempo_total,timer:now_diff(now(),Time)}]),        
        loop_hard_drive(NewStats);
    {cargar_pag, {Id, Pag, CPU}} -> 
        Time=now(),
        %enviar mensaje a kernel con pagina cargada pag_cargada
        kernel ! {pag_cargada, {Id, Pag, CPU}},
                %io:format("pag_cargada~n"),
        NewStats=sim_stat:sumar_all(Stats,[{peticiones,1},{tiempo_total,timer:now_diff(now(),Time)}]),                        
        loop_hard_drive(NewStats);
    {sim_exit, Dic} ->
      mem_manager ! {sim_exit, dict:store(hard_drive, Stats, Dic)},
      exit(ok)                            
  end,
  %io:format("Llego un mensaje~n"),
  %agregar algo al resumen
  loop_hard_drive(Stats).

%
%
%
%
%
start() ->
   % io:format("Hola soy el disco.~n"),
    Stats = sim_stat:init_all(sim_stat:new(hard_drive),
            [{peticiones, 0},{tiempo_total,0}]),    
    loop_hard_drive(Stats).
    
