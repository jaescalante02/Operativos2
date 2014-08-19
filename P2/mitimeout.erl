-module(mitimeout).
-export([clock/3]).



%Esto ejecuta un reloj que hace una interrupcion a Proceso cada Time segundos
clock(Proceso,Time,Nombre_senial) ->
	receive
	after
		Time ->
			Proceso ! Nombre_senial
	end,
	clock(Proceso,Time,Nombre_senial).
