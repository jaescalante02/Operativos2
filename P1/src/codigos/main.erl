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

%
% Argumentos:
% 1. Numero de cores
% 2. Milisegundos de cpu entregados a un proceso
% 3. Bytes de la pagina
% 4. Bytes de una pagina
% 5. Archivo XML
% 6. 
%
start([Ncpu, Timeout, MemT, PagMem, XMLname]) ->
    io:format("~p~n", [Ncpu]),
    Processes = read_process(XMLname),      
    register(kernel, 
      spawn(sim_kernel, start,
           [list_to_integer(atom_to_list(Ncpu)),
            list_to_integer(atom_to_list(Timeout)),
            list_to_integer(atom_to_list(MemT)),
            length(Processes)            
           ])
    ),
    io:format("~p~n", [Processes]),
    send_processes(Processes).
    %, 
    %kernel ! {peticion_memoria,{1,2,3}}.
    %
    %{id,tam,[1,3,6,7]} el arrival se quita
    %
    %exit(ok).
    
