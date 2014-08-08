-module(sim_ready_queue).
-export([start/0]).

%
%
%
%
%
loop_ready_queue(Queue, Stats)->
        %io:format("~p~n", [queue:in(p3,queue:in(p2,queue:in(p1,Queue)))]),  
  NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}]),                
  receive
    {encolar_momentaneo, {Id, CPU}} -> 
        %regresa de inmediato manda ready_process
        Q1 = queue:in(Id, Queue),
        {{value, IDnew}, Q2} = queue:out(Q1),
        kernel ! {ready_process, {IDnew, CPU}},
        loop_ready_queue(Q2, NewStats);
    {encolar, Id} ->
        %No hay cpu disponible
        loop_ready_queue(queue:in(Id,Queue), NewStats);
    {cpu_disponible, CPU}->
        %cpudisponible    
        Empty =queue:is_empty(Queue),
        if 
          (Empty=:=true)-> 
            kernel ! {free_cpu, CPU};                  
          (true)-> 
            {{value, IDnew}, Q1} = queue:out(Queue),  
            kernel ! {ready_process, {IDnew, CPU}},
            loop_ready_queue(Q1, NewStats)         
        end;
    {sim_exit, Dic} ->
      main ! {sim_exit, dict:store(ready_queue, NewStats, Dic)},
      exit(ok)  
  end,
%  io:format("Llego un mensaje~n"),
  %agregar algo al resumen
  loop_ready_queue(Queue, NewStats).


%
%
%
%
%
start() ->
  %  io:format("Hola soy la cola de procesos.~n"),
    Stats = sim_stat:init_all(sim_stat:new(ready_queue),
            [{peticiones, 0}]),     
    loop_ready_queue(queue:new(), Stats).
    
