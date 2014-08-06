-module(sim_process).
-export([init/1]).

%
%
%
%
%
init(Process={ID, Arrival, Sizemem, Pags})->
  T = now(),
  receive
  after Arrival -> %o sumarle algo
                               %QUITAR T
    kernel ! {peticion_memoria, T, {ID,Sizemem, Pags}}
  end.
