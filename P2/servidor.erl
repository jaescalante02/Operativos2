-module(servidor).
-export([main/1,main/0]).


cambiar_contenido(_,_,_,[])->
	[];
cambiar_contenido(Proc,Nodo,NewCont,[Head|Tail])->
	[Process,Node,Pid,_] = Head,
	if
		Pid==Proc andalso Nodo==Node->
			[[Process,Node,Pid,NewCont]] ++ cambiar_contenido(Proc,Nodo,NewCont,Tail);
		true->
			[Head] ++ cambiar_contenido(Proc,Nodo,NewCont,Tail)
			
	end.


%La funcion Run Corre el servidor
%Los parametros son
%Principal que es el servidor principal, actual
%Mcast que es la direccion multicat de registro
%Lista que es la Lista de los servidores con sus contenidos
%Clientes que es la lista de clientes 
%Contenido que es el contenido aparte de este servidor
run(Principal, Mcast,Lista,Clientes,Contenido) ->

	io:format("Mi lista de servidores ahora es~n~p~n~n",[Lista]),
	receive
		{nueva_lista,New} ->
			NewLista = New,
			NewClientes = Clientes,
			NewContenido = Contenido;

		revisar_principal->
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido,

			%%Arreglar esto y poner del lado del multicast
			Resp = rpc:call(Principal,erlang,whereis,[servidor]),
			Resp2 = rpc:call(Principal,erlang,is_process_alive,[Resp]),
			io:format("voy~n"),
			if
				Resp==undefined orelse Resp2/=true ->
					%Se cayo el servidor principal,
					%Hacer algoritmo del grandulon
					io:format("Cayo el principal");
				true ->
					ok
			end;


		%Agrega un cliente nuevo al servidor por si luego
		%se cae el servidor principal se envia un msg a cada cliente
		%para que  el servidor actualice a cada cliente con quien es el
		%Principal
		{agregar_cliente,ClienteNuevo} ->
			io:format("Agrego cliente~n~n"),
			NewLista=Lista,
			NewClientes = Clientes ++ [ClienteNuevo],
			NewContenido = Contenido;

		%msg que indica que un cliente quiere ser agregado con lo que 
		%el servidor (se asume que es el principal el que recibe la
		%senial) manda un broadcast mediante el multicast

		{multicast_cliente,Client} ->
			io:format("Multicast del cliente nuevo"),
			{mcast,Mcast} ! {multicast,{agregar_cliente,Client}},
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido;

		{buscar_archivo,Nombre}->
			io:format("Busco version mas reciente archivo"),
			%Resp = buscarArchivo(Nombre,Contenido),
			%{servidor,Principal} ! ,
			NewClientes = Clientes,
			NewContenido = Contenido,
			NewLista = Lista
			;


		{agregar_archivo,{Name,Time}} ->
			io:format("entre~n~n~n"),
			NewClientes = Clientes,
			NewContenido = Contenido++[{Name,Time}],
			NewLista=cambiar_contenido(self(),node(),NewContenido,Lista),
			{mcast,Mcast} ! {nueva_lista,NewLista},
			{mcast,Mcast} ! {multicasts,{nueva_lista,NewLista}}
			;
		
		Otro->
			io:format("~p~n",[Otro]),
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido


	end,
	run(Principal,Mcast,NewLista,NewClientes,NewContenido).


main([Mcast,Principal|_]) -> 
	register(servidor,self()),

		
	P = net_kernel:connect_node(Mcast)==true,
	if
		P ->
			{mcast,Mcast} ! {addme,[servidor,node(),self(),[]]};
		true->
			io:format("Fallo del servidor al registrarse en el multicast.~n"),
			halt(1)
	end,
	spawn(mitimeout,clock,[{servidor,node()},400,revisar_principal]),

	%El multicast debe contener la lista de servidores
	% que estan comunicados con el multicast
	%Inicialmente esta vacia
	%Y tambien posee la lista de clientes replicadas en cada servidor
	%PD: La lista de servidores tiene [NombreProcess,Nodo,Pid,Contenido]
	run(Principal,Mcast,[],[],[]).

main() ->
	io:format("Debe pasar como parametro, la direccion multicast y la direccion del servidor principal~n").
