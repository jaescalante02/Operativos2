-module(sim_mem_manager).
-export([start/1]).

%
%
%
%
%
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
insert_process(Manager, Id, 1, Pags)->
    buddy:insert(Manager, 1, {Id, [hd(Pags)]});    

insert_process(Manager, Id, SizeP, Pags)->
    if
      (length(Pags)>SizeP)-> {NewPags, _} = lists:split(SizeP, Pags);
      (true)->  NewPags=Pags
    end, 
    New = buddy:insert(Manager, SizeP, {Id, NewPags}),
    if
      (New==fail)->  Resp=insert_process(Manager, Id, next_power_2(SizeP) div 2, Pags);
      (true)-> Resp=New                  
    end,
    Resp.


%
%
%
%
%
loop_mem_manager(Manager, Stats)->
  receive
    { asignar_memoria, {Id, Size, Vpags, Pags} } ->

        NewManager = insert_process(Manager, Id, Size, Pags),
        if
        (NewManager==fail)-> 
            kernel ! {no_memory, Id}, 
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),                  
            loop_mem_manager(Manager, NewStats);             
        (true)->
            kernel ! {asignacion_exitosa, {Id, Size, Vpags}},
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),
            NewStats2=sim_stat:push_all(NewStats,[
              {graphic_states, {add, Id, NewManager}}
            ]),  
            loop_mem_manager(NewManager, NewStats2)  
        end;

    { liberar_mem, Id } ->

        NewManager = buddy:eliminar(Manager, Id),
        NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),  
        NewStats2=sim_stat:push_all(NewStats,[
          {graphic_states, {erase, Id, NewManager}}
        ]),  
        loop_mem_manager(NewManager, NewStats2);         
    {change_page, {Id, Pag, CPU} } ->

        NewManager = buddy:modificar_lista(Manager, Id, [Pag]),
        kernel ! {page_found, {Id, Pag, CPU}},
        NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),
        NewStats2=sim_stat:push_all(NewStats, [
          {graphic_states, {load, Id, NewManager}},
          {graphic_states, {ok, nil, NewManager}}
          ]),          
        loop_mem_manager(NewManager, NewStats2);                            
    {search_page, {Id, Pag, CPU}} -> 

        Cargada = buddy:esta_cargada(Manager, Id, Pag),
        if
          (Cargada==true)-> 
            kernel ! {page_found, {Id, Pag, CPU}},
            NewManager=buddy:cambiar_priori(Manager,Id, Pag),
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1}]),
            NewStats2=sim_stat:push_all(NewStats,[
              {graphic_states, {found, Id, NewManager}},
              {graphic_states, {ok, nil, NewManager}}
            ]),            
            loop_mem_manager(NewManager, NewStats2);        
          (true)-> 
            kernel ! {page_fault, {Id, Pag, CPU}},
            NewStats=sim_stat:sumar_all(Stats,[{peticiones, 1},{total_pf,1}]),
            NewStats2=sim_stat:push_all(NewStats,[
              {graphic_states, {fault, Id, Manager}},
              {graphic_states, {ok, nil, Manager}}
            ]),            
            loop_mem_manager(Manager, NewStats2)   
        end;       
    {sim_exit, Dic} ->
      kernel ! {sim_exit, dict:store(mem_manager, Stats, Dic)},
      exit(ok)                                    
  end.

%
%
%
%
%
start(MemT)->
    Stats = sim_stat:init_all(sim_stat:new(mem_manager),
            [{peticiones, 0}, {total_pf, 0}, {max_frag_interna, 0},
            {mem_total, next_power_2(MemT)}, 
            {graphic_states, [{ok, nil, buddy:crear_arbol(next_power_2(MemT))}]}
            ]),     
    loop_mem_manager(buddy:crear_arbol(next_power_2(MemT)), Stats). 
    
    
    
