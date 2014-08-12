% Representa un reloj encargado de dar timeout en un CPU.
-module(sim_timer).
-export([start/2]).

%
%
%
%
%
start(Timeout,PID_CPU) ->
    timer:send_after(Timeout, PID_CPU, timeout),
    exit(ok).
