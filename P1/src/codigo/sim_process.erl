% Representa un request de memoria de un proceso para el kernel 
% de un sistema operativo.

-module(sim_process).
-export([init/1]).

%
%
%
%
%
init({ID, Arrival, Sizemem, Pags})->
  T = now(),
  receive
  after Arrival -> 
    kernel ! {peticion_memoria, T, {ID,Sizemem, Pags}}
  end.
