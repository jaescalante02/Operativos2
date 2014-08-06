-module(sim_kernel).
-export([start/4]).

%
%
%
%
%
loop_kernel(CPUs)->
  receive
    {peticion_memoria,T, Process={Id, Size, Vpags} } ->
        %enviar mensaje a hard_drive cargar_process io:format("Llego ~p~n", [Process]),        
        hard_drive ! {cargar_process, Process},
        io:format("RECIBI UN PETICION DE MEMORIA ~p~n",[timer:now_diff(now(),T)]), 
        loop_kernel(CPUs);
        
    {proceso_cargado, Process = {Id, Size, Vpags, Pags} } ->
        %enviar mensaje a mem_manager asignar_memoria
        mem_manager ! {asignar_memoria, Process},
        loop_kernel(CPUs);               
        
    {asignacion_exitosa, Process = {Id, Size, Vpags} } ->
        %enviar mensaje a TP (agregar_proceso) y CL
        process_table ! {agregar_proceso, Process},        
        if
          (CPUs=:=[])->
            ready_queue ! {encolar, Id},
            loop_kernel(CPUs);
          (true)->
            ready_queue ! {encolar_momentaneo, {Id, hd(CPUs)}},
            loop_kernel(tl(CPUs))
        end;
    {ready_complete_process, Process = {Id, Size, Vpags, CPU} } ->
        %enviar mensaje a CPU falta
        CPU ! {next_process, {Id, Size, Vpags}},
        loop_kernel(CPUs);         
        
    {ready_process, Process = {Id, CPU} } ->
        %enviar mensaje a TP
        process_table ! {get_process, Process},
        loop_kernel(CPUs);    
                                              
    {finish_process, {Id, CPU} } -> %falta
        %enviar mensaje a TP (eliminar_proceso) y MM (liberar_mem) #falta CL
        io:format("Finish ~p~n",[Id]),
        process_table ! {eliminar_proceso, Id},
        mem_manager ! {liberar_mem, Id},
        ready_queue ! {cpu_disponible, CPU},
        loop_kernel(CPUs);
        
    {free_cpu, CPU}->
        loop_kernel([CPU|CPUs]);  
        
    {timeout_process, {Id, Size, Vpags, CPU} } -> %falta
        %enviar mensaje a CL encolar_momentaneo y TP actualizar_proceso
        process_table ! {actualizar_proceso, {Id, Size, Vpags}}, 
        ready_queue ! {encolar_momentaneo, {Id, CPU}},
        loop_kernel(CPUs);

    {need_page, {Id, Pag, CPU} } -> %falta
        %enviar mensaje a mem_manager
        mem_manager ! {search_page, {Id, Pag, CPU}},
        loop_kernel(CPUs);  
        
    {page_fault, {Id, Pag, CPU} } -> %falta
        %enviar mensaje a HD 
        %io:format("Page Fault~n"),
        hard_drive ! {cargar_pag, {Id, Pag, CPU}},
        loop_kernel(CPUs); 

    {page_found, {Id, Pag, CPU} } ->
        %enviar mensaje al CPU take_page
                %io:format("Page Found~n"),
        CPU ! {take_page, {Id, Pag}},
        loop_kernel(CPUs);

    {pag_cargada, {Id, Pag, CPU} } -> %falta
        %enviar mensaje a MM
                %io:format("almost change_Page~n"),        
        mem_manager ! {change_page, {Id, Pag, CPU}},
                %io:format("change_Page~n"),
        loop_kernel(CPUs)

  end,
  io:format("Llego un mensaje~n"),
  %agregar algo al resumen
  loop_kernel(CPUs).
    
    %request->MM agregar proceso
    %MM->CL
    %  ->TP
    %CPU->CL timeout
    %CL->CPU asigna proceso
    %CPU->TP
    %   ->MM

%
%
%
%
%
create_cpu(_, 0)-> [];
create_cpu(Timeout, Ncpu)->
    PID = spawn(sim_cpu,start, [Timeout]),
    io:format("Creado CPU~p~n",[Ncpu]),
    [PID| create_cpu(Timeout, Ncpu-1)].    

%
%
%
%
%
start(Ncpu, Timeout, MemT, NumP) ->
    io:format("Hola soy el kernel.~p~n",[self()]),
    CPUs=create_cpu(Timeout, Ncpu),
    %io:format("~p~n",[CPUs]),
    register(process_table,spawn(sim_process_table, start, [NumP])),
    register(hard_drive,spawn(sim_hard_drive, start, [])),
    register(ready_queue,spawn(sim_ready_queue, start, [])),
    register(mem_manager,spawn(sim_mem_manager, start, [MemT])),
    loop_kernel(CPUs).
    
    
    
    
    
    
