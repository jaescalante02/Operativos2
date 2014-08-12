-module(sim_cpu).
-export([start/1]).


%
%
%
%
%
processing(Stats, _, {Id, _, []}, Time_init_u)-> 

  kernel ! {finish_process, {Id, self()}},
  sim_stat:sumar_all(Stats,
      [{tuso_ind,timer:now_diff(now(),Time_init_u)}]);
           
processing(Stats, Timeout, {Id, Size, [Pag | Vpags]}, Time_init_u)->

  kernel ! {need_page, {Id, Pag, self()}},
  receive
    {take_page, {Id, Pag}} ->
    
        NewStats = processing(Stats, Timeout, {Id, Size, Vpags}, Time_init_u);          
    timeout ->

      NewStats=sim_stat:sumar_all(Stats,[{tuso_ind,timer:now_diff(now(),Time_init_u)}]),        
      kernel ! {timeout_process, {Id, Size, [Pag | Vpags], self()}}
  end,
  NewStats.

%
%
%
%
%
loop_cpu(Time_init,Timeout, Stats)->

  receive
    {next_process, Process={_, _, _}} ->
    
        Time_init_u=now(),
        spawn(sim_timer, start, [Timeout,self()]),
        NewStats = processing(Stats, Time_init, Process, Time_init_u),
        loop_cpu(Time_init, Timeout, NewStats);
    {sim_exit, [CPU | CPUs], Dic} ->
    
      NewStats=sim_stat:sumar_all(Stats,[
        {peticiones,1},
        {ttotal_ind,timer:now_diff(now(),Time_init)}
      ]),                        
      CPU ! {sim_exit, CPUs, dict:append(cpus, NewStats, Dic)},
      exit(ok);      
    {sim_exit, [], Dic} ->
    
      NewStats=sim_stat:sumar_all(Stats,[
        {peticiones,1},
        {ttotal_ind,timer:now_diff(now(),Time_init)}
      ]),                        
      ready_queue ! {sim_exit, dict:append(cpus, NewStats, Dic)},
      exit(ok)          
  end,
  loop_cpu(Time_init, Timeout, Stats).

%
%
%
%
%
start(Timeout) ->
    Stats = sim_stat:init_all(sim_stat:new(cpu),
            [{peticiones, 0}, {ttotal_ind, 0},{tuso_ind, 0}, 
             {timeout, Timeout}]),    
    loop_cpu(now(),Timeout, Stats).
    
