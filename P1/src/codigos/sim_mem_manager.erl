-module(sim_mem_manager).
-export([start/1]).


next_power_2(Num)->
    next_power_2_aux(Num,1).
    
next_power_2_aux(Num, Acm)-> 
    if
    (Num>Acm)-> next_power_2_aux(Num, Acm*2);
    (true)-> Acm
    end.    


insert_process(Manager, Id, 1, Pags)->
  %  io:format("Init1~p ~n~n~p ~p~n",[Manager,Id,Pags]),
    New = buddy:insert(Manager, 1, {Id, hd(Pags)}),
    
    if
      (New==Manager)->
          %mensaje  
          Resp=Manager;
      (true)-> Resp=New
    end,
    %io:format("1resp~n~p~n", [Resp]),                     
    Resp;    

insert_process(Manager, Id, SizeP, Pags)->
    if
      (length(Pags)>SizeP)-> {NewPags, _} = lists:split(SizeP, Pags);
      (true)->  NewPags=Pags
    end, 
    %io:format("NEWPAGS~n~p~n", [NewPags]),                 
   % io:format("Init2~p ~n~n~p ~p~n",[Manager,Id,NewPags]),
    New = buddy:insert(Manager, SizeP, {Id, NewPags}),
    %io:format("Newresp~n~p~n", [New]), 
    if
      (New==Manager)->  Resp=insert_process(Manager, Id, next_power_2(SizeP) div 2, Pags);
      (true)-> Resp=New %io:format("3resp~n~p~n", [Resp])                         
    end,
    %io:format("2resp~n~p~n", [Resp]),                         
    Resp.


%
%
%
%
%
loop_mem_manager(Manager, Stats)->
  receive
    { asignar_memoria, Process={Id, Size, Vpags, Pags} } ->
        %wilmer asignacion_exitosa o _
        %como se que falla %falta
        NewManager = insert_process(Manager, Id, Size, Pags),
        if
        (NewManager==fail)-> 
            kernel ! {no_memory, Id}, 
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),                  
            loop_mem_manager(Manager, NewStats);             
        (true)->
            kernel ! {asignacion_exitosa, {Id, Size, Vpags}},
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),                              
            loop_mem_manager(NewManager, NewStats)  
        end;

    { liberar_mem, Id } ->
        %liberas la memoria 
        NewManager = buddy:eliminar(Manager, Id),
        NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),                          
        loop_mem_manager(NewManager, NewStats);         
    {change_page, {Id, Pag, CPU} } ->
        %lru con mensaje para avisar page_found
        NewManager = buddy:modificar_lista(Manager, Id, Pag),
        kernel ! {page_found, {Id, Pag, CPU}},
        NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),
        loop_mem_manager(NewManager, NewStats);                            
    {search_page, {Id, Pag, CPU}} -> 
        %busco una pagina page_fault o page_found falta
        %io:format("~p ~n ~p ~p ~n ",[Manager,Id,Pag]),
        Cargada = buddy:esta_cargada(Manager, Id, Pag),
        if
          (Cargada==true)-> 
            kernel ! {page_found, {Id, Pag, CPU}},
            NewManager=buddy:cambiar_priori(Manager,Id, Pag),
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),
            loop_mem_manager(NewManager, NewStats);        
          (true)-> 
            kernel ! {page_fault, {Id, Pag, CPU}},
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1},{total_pf,1}]),
            loop_mem_manager(Manager, NewStats)   
        end;       
    {sim_exit, Dic} ->
      kernel ! {sim_exit, dict:store(mem_manager, Stats, Dic)},
      exit(ok)                                    
        %io:format("Pong received ping~n", [])
  end.

%
%
%
%
%
start(MemT)->
  %  io:format("Hola soy el manejador de memoria.~n"),
    Stats = sim_stat:init_all(sim_stat:new(mem_manager),
            [{peticiones, 0}, {total_pf, 0}, {max_frag_interna, 0}]),     
    loop_mem_manager(buddy:crear_arbol(next_power_2(MemT)), Stats). %falta potencia 2
    
