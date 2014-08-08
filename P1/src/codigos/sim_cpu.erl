-module(sim_cpu).
-export([start/1]).


%
%
%
%
%
processing(Stats, Timeout, Process={Id, Size, []}, Time_init_u)-> 
        kernel ! {finish_process, {Id, self()}},
        NewStats=sim_stat:sumar_all(Stats,
            [{tuso_ind,timer:now_diff(now(),Time_init_u)}]);
           
processing(Stats, Timeout, Process={Id, Size, [Pag | Vpags]}, Time_init_u)->
  T=now(),
  %ver si puedo hacerlo mas justo con el timeout
  %mando mensaje con # pag al kernel need_page 
  %falta el caso que llega la pagina fuera de tiempo
  kernel ! {need_page, {Id, Pag, self()}}, %falta
  %io:format("CPU:~p ID:~p PAGS:~p~n",[self(),Id, [Pag | Vpags]]),
  receive
    {take_page, {Id, Pag}} ->
   %            io:format("TAKE PAGE~n"),
        %llego la pagina
        %si es la ultima pag diferente de culminación finish_process falta
    %    io:format("Pong finished~n", []),
        NewStats = processing(Stats, Timeout, {Id, Size, Vpags}, Time_init_u);  
    timeout ->
      %timeout_process
      NewStats=sim_stat:sumar_all(Stats,[{tuso_ind,timer:now_diff(now(),Time_init_u)}]),        
      kernel ! {timeout_process, {Id, Size, [Pag | Vpags], self()}}
      %T2=timer:now_diff(now(),T),
	    %io:format("CPU Tiempo con now diff similar a 2segs en microsegs: ~p~n",[T2])                                
  end,
  NewStats.
  %io:format("Llego un mensaje~n"). 

%
%
%
%
%
loop_cpu(Time_init,Timeout, Stats)->
  Time=now(),
  receive
    {next_process, Process={Id, Size, Vpags}} ->
        Time_init_u=now(),
        spawn(sim_timer, start, [Timeout,self()]),
        NewStats = processing(Stats, Time_init, Process, Time_init_u),
        loop_cpu(Time_init, Timeout, NewStats);
    {sim_exit, [CPU | CPUs], Dic} ->
      NewStats=sim_stat:sumar_all(Stats,[{peticiones,1},{ttotal_ind,timer:now_diff(now(),Time_init)}]),                        
      CPU ! {sim_exit, CPUs, dict:append(cpus, NewStats, Dic)},
      exit(ok);
    {sim_exit, [], Dic} ->
      NewStats=sim_stat:sumar_all(Stats,[{peticiones,1},{ttotal_ind,timer:now_diff(now(),Time_init)}]),                        
      ready_queue ! {sim_exit, dict:append(cpus, NewStats, Dic)},
      exit(ok)          
  end,
  %agregar algo al resumen
  loop_cpu(Time_init, Timeout, Stats).

%
%
%
%
%
start(Timeout) ->
    %io:format("Hola soy el CPU.~n"),
    Stats = sim_stat:init_all(sim_stat:new(cpu),
            [{peticiones, 0}, {ttotal_ind, 0},{tuso_ind, 0}, 
             {timeout, Timeout}]),    
    loop_cpu(now(),Timeout, Stats).
    
