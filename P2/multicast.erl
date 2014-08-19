-module(multicast).
-export([main/1,main/0,enviar_multicast/2]).

revisar([]) ->
	[];
revisar([[Process,Node,Pid | Cont]|Resto])->
	Cond = 	rpc:call(Node,erlang,is_process_alive,[Pid])==true,
%	Cond = 	rpc:call(Node,erlang,whereis,[Process]),  
	%io:format("Cond ~p~n",[Cond]),
	if
		Cond ->
			[[Process,Node,Pid | Cont]] ++ revisar(Resto);
		true ->
			revisar(Resto)
	end.


enviar_multicast(_,[])->
	ok;

enviar_multicast(Msg,[[Proces,Serv|_]|Resto]) ->
	{Proces,Serv} ! Msg,
	enviar_multicast(Msg,Resto).

%%Funcion principal de la direccion multicast
main(Lista) ->
	io:format("Lista de servidores afiliados: ~n ~p~n~n~n",[Lista]),

	receive
		%Agrego servidor a la lista de registrados
		%Servidor es una lista de [Proceso,Nodo]
		{addme,Servidor} ->
			NewLista = Lista ++ [Servidor],
		 	enviar_multicast({nueva_lista,NewLista},NewLista);

		{nueva_lista,NewLista}->
			ok;

		revisar_vivos ->
			NewLista = revisar(Lista),
			Cond = NewLista/=Lista,
			if
				Cond ->
					enviar_multicast({nueva_lista,NewLista},NewLista);
				true ->
					ok
			end;

		{unicasts,To,Msg} ->
			To ! Msg,
			NewLista = Lista;

		{multicasts,Msg} ->
			NewLista = Lista,
			enviar_multicast(Msg,Lista)
	end,
	multicast:main(NewLista).


%Ejecuta el multicast y lo deja como servidor
main() ->
	register(mcast,self()),
	%Se crea un reloj para que el multicast revise quienes estan vivos,
	%de los que se suscribieron
	spawn(mitimeout,clock,[{mcast,node()},500,revisar_vivos]),

	%La lista pasada al otro main, es la lista de servidores activos o registrados
	%Inicialmente no hay
	main([]).
