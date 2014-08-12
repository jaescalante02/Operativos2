% Representa un manejo muy sencillo de la accion de un Kernel.
-module(sim_kernel).
-export([start/4]).

%
%
%
%
%
loop_kernel(CPUs, Stats)->
  NewStats=sim_stat:sumar_all(Stats,[{peticiones,1}]),        
  receive
    {peticion_memoria, _, Process={ _, _, _} } ->

        hard_drive ! {cargar_process, Process},
        loop_kernel(CPUs, NewStats);
        
    {proceso_cargado, Process = { _, _, _, _} } ->

        mem_manager ! {asignar_memoria, Process},
        loop_kernel(CPUs, NewStats);               
        
    {asignacion_exitosa, Process = {Id, _, _} } ->

        process_table ! {agregar_proceso, Process},        
        if
          (CPUs=:=[])->
            ready_queue ! {encolar, Id},
            loop_kernel(CPUs, NewStats);
          (true)->
            ready_queue ! {encolar_momentaneo, {Id, hd(CPUs)}},
            loop_kernel(tl(CPUs), NewStats)
        end;
    
    {no_memory, Id}->
        process_table ! {fail_creation,Id};
                
    {ready_complete_process, {Id, Size, Vpags, CPU} } ->

        CPU ! {next_process, {Id, Size, Vpags}},
        loop_kernel(CPUs, NewStats);         
        
    {ready_process, Process = { _, _} } ->

        process_table ! {get_process, Process},
        loop_kernel(CPUs, NewStats);    
                                              
    {finish_process, {Id, CPU} } -> 

        process_table ! {eliminar_proceso, Id},
        mem_manager ! {liberar_mem, Id},
        ready_queue ! {cpu_disponible, CPU},
        loop_kernel(CPUs, NewStats);
        
    {free_cpu, CPU}->
        loop_kernel([CPU|CPUs], NewStats);  
        
    {timeout_process, {Id, Size, Vpags, CPU} } -> 

        process_table ! {actualizar_proceso, {Id, Size, Vpags}}, 
        ready_queue ! {encolar_momentaneo, {Id, CPU}},
        loop_kernel(CPUs, NewStats);

    {need_page, {Id, Pag, CPU} } -> 

        mem_manager ! {search_page, {Id, Pag, CPU}},
        loop_kernel(CPUs, NewStats);  
        
    {page_fault, {Id, Pag, CPU} } -> 

        hard_drive ! {cargar_pag, {Id, Pag, CPU}},
        loop_kernel(CPUs, NewStats); 

    {page_found, {Id, Pag, CPU} } ->

        CPU ! {take_page, {Id, Pag}},
        loop_kernel(CPUs, NewStats);

    {pag_cargada, {Id, Pag, CPU} } -> 

        mem_manager ! {change_page, {Id, Pag, CPU}},
        loop_kernel(CPUs, NewStats);
    {sim_exit, Dic} ->
    
      hd(CPUs) ! {sim_exit, tl(CPUs), dict:store(kernel, Stats, Dic)},
      exit(ok) 

  end,
  loop_kernel(CPUs, Stats).
    
%
%
%
%
%
create_cpu(_, 0)-> [];
create_cpu(Timeout, Ncpu)->
    PID = spawn(sim_cpu,start, [Timeout]),
    [PID| create_cpu(Timeout, Ncpu-1)].    

%
%
%
%
%
start(Ncpu, Timeout, MemT, NumP) ->

    CPUs=create_cpu(Timeout, Ncpu),
    register(process_table,spawn(sim_process_table, start, [NumP])),
    register(hard_drive,spawn(sim_hard_drive, start, [])),
    register(ready_queue,spawn(sim_ready_queue, start, [])),
    register(mem_manager,spawn(sim_mem_manager, start, [MemT])),
    Stats = sim_stat:init_all(sim_stat:new(kernel),
            [{peticiones, 0}]),     
    loop_kernel(CPUs, Stats).
    
    
    
    
    
    
