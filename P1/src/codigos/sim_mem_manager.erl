-module(sim_mem_manager).
-export([start/1]).


next_power_2(Num)->
    next_power_2_aux(Num,1).
    
next_power_2_aux(Num, Acm)-> 
    if
    (Num>Acm)-> next_power_2_aux(Num, Acm*2);
    (true)-> Acm
    end.    



%
%
%
%
%
loop_mem_manager(Manager)->
  receive
    { asignar_memoria, Process={Id, Size, Vpags, Pags} } ->
        %wilmer asignacion_exitosa o _
        %como se que falla %falta
        kernel ! {asignacion_exitosa, {Id, Size, Vpags}},
        % y si falla?
        loop_mem_manager(Manager); 
    { liberar_mem, Id } ->
        %liberas la memoria 
        NewManager = buddy:eliminar(Manager, Id),
        loop_mem_manager(NewManager);         
    {change_page, {Id, Pag, CPU} } ->
        %lru con mensaje para avisar page_found
        NewManager = buddy:modificar_lista(Manager, Id, Pag), %falta
        kernel ! {page_found, {Id, Pag, CPU}},
        loop_mem_manager(Manager);                            
    {search_page, {Id, Pag, CPU}} -> 
        %busco una pagina page_fault o page_found falta
        Cargada = buddy:esta_cargada(Manager, Id, Pag),
        if
          (Cargada==true)-> kernel ! {page_found, {Id, Pag, CPU}};        
          (true)-> kernel ! {page_fault, {Id, Pag, CPU}}
        end,
        loop_mem_manager(Manager)                                   
        %io:format("Pong received ping~n", [])
  end.

%
%
%
%
%
start(MemT)->
    io:format("Hola soy el manejador de memoria.~n"),
    loop_mem_manager(buddy:new(next_power_2(MemT))). %falta potencia 2
    
