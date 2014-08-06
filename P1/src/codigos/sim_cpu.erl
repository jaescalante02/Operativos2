-module(sim_cpu).
-export([start/1]).


%
%
%
%
%
processing(Timeout, Process={Id, Size, []})-> kernel ! {finish_process, {Id, self()}};
processing(Timeout, Process={Id, Size, [Pag | Vpags]})->
  T=now(),
  %ver si puedo hacerlo mas justo con el timeout
  %mando mensaje con # pag al kernel need_page 
  %falta el caso que llega la pagina fuera de tiempo
  kernel ! {need_page, {Id, Pag, self()}}, %falta
  io:format("CPU:~p ID:~p PAGS:~p~n",[self(),Id, [Pag | Vpags]]),
  receive
    {take_page, {Id, Pag}} ->
               io:format("TAKE PAGE~n"),
        %llego la pagina
        %si es la ultima pag diferente de culminación finish_process falta
        io:format("Pong finished~n", []),
        processing(Timeout, {Id, Size, Vpags});  
    timeout ->
      %timeout_process
      kernel ! {timeout_process, {Id, Size, [Pag | Vpags], self()}}
      %T2=timer:now_diff(now(),T),
	    %io:format("CPU Tiempo con now diff similar a 2segs en microsegs: ~p~n",[T2])                                
  end.
  %io:format("Llego un mensaje~n"). 

%
%
%
%
%
loop_cpu(Timeout)->
  T=now(),
  receive
    {next_process, Process={Id, Size, Vpags}} ->
        spawn(sim_timer, start, [Timeout,self()]),
        processing(Timeout, Process)      
  end,
  %agregar algo al resumen
  loop_cpu(Timeout).

%
%
%
%
%
start(Timeout) ->
    io:format("Hola soy el CPU.~n"),
    loop_cpu(Timeout).
    
