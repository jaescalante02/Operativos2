-module(sim_ready_queue).
-export([start/0]).

%
%
%
%
%
loop_ready_queue(Queue)->
        %io:format("~p~n", [queue:in(p3,queue:in(p2,queue:in(p1,Queue)))]),  
  receive
    {encolar_momentaneo, {Id, CPU}} -> 
        %regresa de inmediato manda ready_process
        Q1 = queue:in(Id, Queue),
        {{value, IDnew}, Q2} = queue:out(Q1),
        kernel ! {ready_process, {IDnew, CPU}},
        loop_ready_queue(Q2);
    {encolar, Id} ->
        %No hay cpu disponible
        loop_ready_queue(queue:in(Id,Queue));
    {cpu_disponible, CPU}->
        %cpudisponible    
        Empty =queue:is_empty(Queue),
        if 
          (Empty=:=true)-> 
            kernel ! {free_cpu, CPU};                  
          (true)-> 
            {{value, IDnew}, Q1} = queue:out(Queue),  
            kernel ! {ready_process, {IDnew, CPU}},
            loop_ready_queue(Q1)         
        end  
  end,
  io:format("Llego un mensaje~n"),
  %agregar algo al resumen
  loop_ready_queue(Queue).


%
%
%
%
%
start() ->
    io:format("Hola soy la cola de procesos.~n"),
    loop_ready_queue(queue:new()).
    
