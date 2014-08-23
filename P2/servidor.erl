-module(servidor).
-export([main/1,main/0,cambiar_contenido/4]).


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

enviar_msg_fifo(Lista,_,0,_) ->
	Lista;

enviar_msg_fifo([Head|Resto],Msg,K,Mcast) ->
	[Process,Node,_,_] = Head,
	{mcast,Mcast} ! {unicasts,{Process,Node},Msg},
	enviar_msg_fifo(Resto++[Head],Msg,K-1,Mcast).
	


grandulon([],Minimo) ->
	element(2,Minimo);

grandulon([[_,Nodo,Pid,_]|Resto],nil) ->
	Resp = rpc:call(Nodo,erlang,whereis,[servidor]),
	Resp2 = rpc:call(Nodo,erlang,is_process_alive,[Resp])==true,
	if
		Resp==undefined orelse Resp2/=true->
			grandulon(Resto,nil);
		true-> 
			grandulon(Resto,{Pid,Nodo})
	end;

grandulon([[_,Nodo,Pid,_]|Resto],Compare) ->
	Resp = rpc:call(Nodo,erlang,whereis,[servidor]),
	Resp2 = rpc:call(Nodo,erlang,is_process_alive,[Resp])==true,
	if
		Resp==undefined orelse Resp2/=true orelse {Pid,Nodo} > Compare ->
			grandulon(Resto,{Pid,Nodo})
		;
		true->
			grandulon(Resto,Compare)
	end.
	

%La funcion Run Corre el servidor
%Los parametros son
%OldPrincipal que es el servidor principal, actual
%Mcast que es la direccion multicat de registro
%Lista que es la Lista de los servidores con sus contenidos
%Clientes que es la lista de clientes 
%Contenido que es el contenido aparte de este servidor
run(Principal, Mcast,Lista,Clientes,Contenido,Red) ->

	io:format("Mi lista de servidores ahora es~n~p~n~n",[Lista]),
	io:format("Y clientes: ~n~p~n~n",[Clientes]),
	io:format("Y el servidor principal: ~n~p~n",[Principal]),

	%Son respuestas a llamadas mediante rpc's al servidor principal
	Resp3 = rpc:call(Principal,erlang,whereis,[servidor]),
	Resp4 = rpc:call(Principal,erlang,is_process_alive,[Resp3])==true,
	if
		Resp3==undefined orelse Resp4/=true ->
			%Se cayo el servidor principal,
			%Hacer algoritmo del grandulon
			io:format("~n~n#####Cayo el principal#####~n~n"),
			NewS1 = grandulon(Lista,nil),
		%	NewS1 = Principal,
			%io:format("Ahora principal~n:~p~n",[NewS1]);
			run(NewS1, Mcast,Lista,Clientes,Contenido,Red);
		true ->
			ok
	end,
	io:format("Y principal2: ~n~p~n",[Principal]),

	receive
		{dar_lista_cliente,From} ->
			From ! {recibir_lista_cliente,Clientes},
			NewLista = Lista,
			NewClientes = Clientes,
			NewContenido = Contenido;

		{dar_lista_servidor,From} ->
			From ! {recibir_lista_servidor,Lista},
			NewLista = Lista,
			NewClientes = Clientes,
			NewContenido = Contenido;


		{nueva_lista,New} ->
			NewLista = New,
			NewClientes = Clientes,
			NewContenido = Contenido;

		{nueva_lista_cl,Clients}->
			NewLista = Lista,
			NewClientes = Clients,
			NewContenido = Contenido;


		revisar_principal->
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido,
			io:format("Principal3~n"),
			%%Arreglar esto y poner del lado del multicast
			Resp = rpc:call(Principal,erlang,whereis,[servidor]),
			io:format("Principal44~n"),
			%Resp=ctm,
			%Resp2=true,
			Resp2 = (rpc:call(Principal,erlang,is_process_alive,[Resp])==true),
			io:format("Principal4~n"),

			if

				Resp/=undefined orelse Resp2/=true ->
					%Se cayo el servidor principal,
					%Hacer algoritmo del grandulon
					io:format("~n~n#####Cayo el principal#####~n~n"),
					NewS = grandulon(Lista,nil),
					io:format("Ahora principal~n:~p~n",[NewS]);
		%			run(NewS, Mcast,Lista,Clientes,Contenido,Red);
				true ->
					ok
		
			end;

		{peticion_agregar_cliente,ClienteNuevo} ->
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido,
			{mcast,Mcast} ! {multicasts,{agregar_cliente,ClienteNuevo}}
			;

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

		{peticion_agregar_archivo,Arch} ->
			NewLista = enviar_msg_fifo(Lista,{agregar_archivo,Arch},Red+1,Mcast),
			NewClientes = Clientes,
			NewContenido = Contenido
			;
	
		{agreguen_servidor,S} ->
			NewClientes = Clientes,
			NewContenido = Contenido,
			NewLista = Lista++[S],
			[_,Nodo,_,_] = S,
			{mcast,Mcast} ! {unicasts,{servidor,Nodo},{nueva_lista,NewLista}},
			{mcast,Mcast} ! {unicasts,{servidor,Nodo},{nueva_lista_cl,Clientes}};

			

		{agregar_archivo,Arch} ->
			io:format("entre~n~n~n"),
			NewClientes = Clientes,
			Contengo = lists:delete(Arch,Contenido),
			NewContenido = Contengo++[Arch],
			ContenidoAAgregar = NewContenido,
			NewLista=Lista,
			{mcast,Mcast} ! {cambio_contenido,{self(),node(),NewContenido}},
			{mcast,Mcast} ! {multicasts,{cambio_contenido,{self(),node(),ContenidoAAgregar}}}
			;
		
		{cambio_contenido,{Proc,Nodo,NuevoCont}} ->
			NewClientes = Clientes,
			NewContenido = Contenido,
			NewLista = cambiar_contenido(Proc,Nodo,NuevoCont,Lista);

		{muertos,ListaM} ->
			NewClientes = Clientes,
			NewContenido = Contenido,
			NewLista = multicast:fuera_muertos(Lista,ListaM);

		Otro->
			io:format("Cayooooo aquiiiii ~n~p~n",[Otro]),
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido


	end,
	run(Principal,Mcast,NewLista,NewClientes,NewContenido,Red).


recibir_clientes()->
	receive
		{recibir_lista_cliente,Clientes} ->
			Clientes;
		_->
			recibir_clientes()
	after 2000 ->
			[]
	end.

recibir_servidores()->
	receive
		{recibir_lista_servidor,Servidores} ->
			Servidores;
		_->
			recibir_servidores()
	after 2000 ->
			[]
	end.		
	


main([Mcast,Principal,K|_]) -> 
	register(servidor,self()),

	Number = atom_to_list(K),
	{Redundancia,Resto} = string:to_integer(Number),
	P = net_kernel:connect_node(Mcast)==true,
	if
		not (P) ->
			io:format("Fallo del servidor al registrarse en el multicast.~n"),
			halt(1);
		true ->
			ok
	end,
	if
		(not (is_number(Redundancia))) orelse []/=Resto->
			io:format("El parametro de redundancia debe ser un numero.~n"),
			halt(1);
		true ->
			ok
	end,

%	{mcast,Mcast} ! {multicast,{dar_lista_cliente,{self(),node()}}},
%	{mcast,Mcast} ! {multicast,{dar_lista_servidor,{self(),node()}}},
%	Client = recibir_clientes(),
%	Serv = recibir_servidores(),
	{mcast,Mcast} ! {addme,[servidor,node(),self(),[]]},

	spawn(mitimeout,clock,[{servidor,node()},200,revisar_principal]),

	%El multicast debe contener la lista de servidores
	% que estan comunicados con el multicast
	%Inicialmente esta vacia
	%Y tambien posee la lista de clientes replicadas en cada servidor
	%PD: La lista de servidores tiene [NombreProcess,Nodo,Pid,Contenido]
	run(Principal,Mcast,[],[],[],Redundancia).

main() ->
	io:format("Debe pasar como parametro, la direccion multicast, la direccion del servidor principal, y un numero K que indica la redundancia~n").
