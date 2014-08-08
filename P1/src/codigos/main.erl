-module(main).
-export([start/1]).

%
%
%
%
%
process_items([{_, Num}| L], Resp)->process_items(L, [list_to_integer(Num) | Resp]);
process_items([], Resp)-> Resp.

%
%
%
%
%
create_processes([])->[];
create_processes([{_,ID}, Items | L])-> 
    [Arrival, Size| Pags] = process_items(Items, []),
    [{ID, Arrival, Size, Pags} | create_processes(L)].


%
%
%
%
%
read_process(XMLname)->
  Aux_read = xml_reader:parse(XMLname),
  create_processes(Aux_read).


%
%
%
%
%
send_processes([])->ok;
send_processes([Process | L])->
  spawn(sim_process, init, [Process]),
  send_processes(L).

imprimir_disco(Dic)->
    {ok,{_,Disco}} = dict:find(hard_drive,Dic),
    io:format("Estadisticas del dicso:~n"),
    {ok,Pet} = dict:find(peticiones,Disco),
    {ok,Tiempo} = dict:find(tiempo_total,Disco),
    io:format("\tTotal de peticiones: ~p~n",[Pet]),
    io:format("\tTiempo total de uso: ~p~n~n",[Tiempo/1000]).

imprimir_kernel(Dic)->
    {ok,{_,Kernel}} = dict:find(kernel,Dic),
    io:format("Estadisticas del kernel:~n"),
    {ok,Pet} = dict:find(peticiones,Kernel),
    io:format("\tTotal de peticiones: ~p~n~n",[Pet]).
    
imprimir_ready_queue(Dic)->
    {ok,{_,Queue}} = dict:find(ready_queue,Dic),
    io:format("Estadisticas de la cola de listos:~n"),
    {ok,Pet} = dict:find(peticiones,Queue),
    io:format("\tTotal de peticiones: ~p~n~n",[Pet]).

imprimir_tabla_de_procesos(Dic)->
    {ok,{_,Table}} = dict:find(process_table,Dic),
    io:format("Estadisticas de la tabla de procesos:~n"),
    {ok,Pet} = dict:find(peticiones,Table),
    {ok,At} = dict:find(atendidos,Table),
    {ok,Sum} = dict:find(sum_vpags,Table),
    {ok,Total} = dict:find(totales,Table),
    io:format("\tTotal de peticiones: ~p~n",[Pet]),
    io:format("\tTotal de procesos atendidos: ~p~n",[At]),
    io:format("\tPromedio de paginas por proceso: ~p~n",[Sum/At]),
    io:format("\tTotal de paginas requeridas: ~p~n",[Sum]),
    io:format("\tPorcentaje de paginas atendidas: ~p%~n",[At*100/Total]).

%ttotal_ind
%tuso_ind
%timeout

suma_uso_cpus([])->
  0;
suma_uso_cpus([{_,X}|Y])->
  {_,T} = dict:find(tuso_ind,X),
  T + suma_uso_cpus(Y).

suma_cpus([])->
  0;
suma_cpus([{_,X}|Y])->
  {_,T} = dict:find(ttotal_ind,X),
  T + suma_cpus(Y).

imprimir_cpu_ind([],_)->
  io:format("");
  
imprimir_cpu_ind([{_,X}|Y],Z)->
    io:format("\tEstadistica del CPU ~p:~n",[Z]),
    {_,T} = dict:find(tuso_ind,X),
    io:format("\t\tTiempo de uso: ~p~n",[T]),
    {_,T2} = dict:find(ttotal_ind,X),
    io:format("\t\tTiempo total: ~p~n",[T2]),
    {_,Q} = dict:find(timeout,X),
    io:format("\t\tQuantum: ~p~n~n",[Q]),
    imprimir_cpu_ind(Y,Z+1).

imprimir_CPU(Dic)->
    {ok,CPU} = dict:find(cpus,Dic),
    io:format("Estadisticas de los CPUs:~n"),
    imprimir_cpu_ind(CPU,1),
    Stotal = suma_cpus(CPU),
    Suso = suma_uso_cpus(CPU),
    io:format("Tiempo total de uso de los CPUs: ~p~n",[Suso]),
    io:format("Tiempo total de los CPUs: ~p~n~n",[Stotal]).

imprimir_MEM(Dic)->
    {ok,{_,Mem}} = dict:find(mem_manager,Dic),
    {ok,Pet} = dict:find(peticiones,Mem),
    {ok,Sf} = dict:find(total_pf,Mem),
    io:format("Estadisticas de memoria:~n"),
    io:format("\tTotal de peticiones: ~p~n",[Pet]),
    io:format("\tTotal de page faults: ~p~n~n",[Sf]).

%
% Argumentos:
% 1. Numero de cores
% 2. Milisegundos de cpu entregados a un proceso
% 3. Bytes de la pagina
% 4. Bytes de una pagina
% 5. Archivo XML
% 6. 
%
start([Ncpu, Timeout, MemT, XMLname]) ->
    Init = now(),
    %io:format("~p~n", [Ncpu]),
    Processes = read_process(XMLname),
    register(main, self()),      
    register(kernel, 
      spawn(sim_kernel, start,
           [list_to_integer(atom_to_list(Ncpu)),
            list_to_integer(atom_to_list(Timeout)),
            list_to_integer(atom_to_list(MemT)),
            length(Processes)            
           ])
    ),
    %io:format("~p~n", [Processes]),
    send_processes(Processes),
    receive
      {sim_exit, Dic} ->
      %  io:format("LLEGO al main~n~p~n", [Dic]),
        imprimir_disco(Dic),
        imprimir_kernel(Dic),
        imprimir_ready_queue(Dic),
        imprimir_tabla_de_procesos(Dic),
        imprimir_CPU(Dic),
        imprimir_MEM(Dic)
    end,
    io:format("~nTiempo total del programa: ~p segundos.~n",[timer:now_diff(now(),Init) / 1000000]).
    %, 
    %kernel ! {peticion_memoria,{1,2,3}}.
    %
    %{id,tam,[1,3,6,7]} el arrival se quita
    %
    %exit(ok).
    
