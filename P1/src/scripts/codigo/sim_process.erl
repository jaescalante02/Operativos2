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
