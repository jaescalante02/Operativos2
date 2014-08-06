-module(sim_hard_drive).
-export([start/0]).

%
%
%
%
%
loop_hard_drive()->
  receive
    {cargar_process, {Id, Size, Npags}} ->
        %enviar mensaje a kernel con lista [0..Npags-1] proceso_cargado
        kernel ! {proceso_cargado, {Id, Size, Npags, lists:seq(0,Size-1)} },
        loop_hard_drive();
    {cargar_pag, {Id, Pag, CPU}} -> 
        %enviar mensaje a kernel con pagina cargada pag_cargada
        kernel ! {pag_cargada, {Id, Pag, CPU}},
                %io:format("pag_cargada~n"),
        loop_hard_drive()
  end,
  %io:format("Llego un mensaje~n"),
  %agregar algo al resumen
  loop_hard_drive().

%
%
%
%
%
start() ->
    io:format("Hola soy el disco.~n"),
    loop_hard_drive().
    
