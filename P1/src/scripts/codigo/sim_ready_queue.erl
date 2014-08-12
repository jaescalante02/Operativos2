-module(sim_ready_queue).
-export([start/0]).

%
%
%
%
%
loop_ready_queue(Queue, Stats)->

  NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}]),                
  receive
    {encolar_momentaneo, {Id, CPU}} -> 

        Q1 = queue:in(Id, Queue),
        {{value, IDnew}, Q2} = queue:out(Q1),
        kernel ! {ready_process, {IDnew, CPU}},
        loop_ready_queue(Q2, NewStats);
    {encolar, Id} ->

        loop_ready_queue(queue:in(Id,Queue), NewStats);
    {cpu_disponible, CPU}->

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
  loop_ready_queue(Queue, NewStats).


%
%
%
%
%
start() ->

    Stats = sim_stat:init_all(sim_stat:new(ready_queue),
            [{peticiones, 0}]),     
    loop_ready_queue(queue:new(), Stats).
    
