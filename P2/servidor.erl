-module(servidor).
-export([main/1,cambiar_contenido/4,timest/0,promediacion/5]).

%Funcion que revisa si un proceso esta vivo mediante un Multicast en un Nodo
revisar(_,Nodo)->
	Resp = ok,
	Resp2 = net_adm:ping(Nodo)==pong,
	{Resp,Resp2}.


%Funcion que retorna el tiempo en segundos de una computadora
timest() ->
	calendar:datetime_to_gregorian_seconds({date(),time()}).


%Funcion que dada una lista de servidores calcula el promedio
%de la hora en cada uno de ellos, usada como auiliar para
%Sacar el promedio de las horas de cada computadora

promediacion(_,[],Seg,Vivos,_) ->
	Seg div Vivos;

promediacion(Mcast,[[_,Nodo,_,_]|Resto],Segundos,Vivos,TiempoPromediando) ->
	T1 = now(),
	Resp = rpc:call(Mcast,multicast,hacer_rpc,[Nodo,servidor,timest,[]]),
	T2 = now(),
	Tarda = timer:now_diff(T2,T1) div 1000000,
	if
		is_number(Resp)->
			promediacion(Mcast,Resto,Segundos+Resp-TiempoPromediando-Tarda,Vivos+1,TiempoPromediando+Tarda)
		;
		true->
			promediacion(Mcast,Resto,Segundos,Vivos,TiempoPromediando+Tarda)
	end.


%Funcion que dado una lista de archivos cuyo nombres son nombre_timestamp
%Devuelve una lista de el nombre separado del timestamp
parsear_archivos([])->
	[];

parsear_archivos([Archivo|Resto])->
	Index = string:str(Archivo,"_"),
	Nombre = string:substr(Archivo,1,Index-1),
	Version = string:substr(Archivo,Index+1),
	[{Nombre,Version}] ++ parsear_archivos(Resto).


%Funcion encargada de cargar todo contenido que posea un directorio 
%Cuando el servidor se levanta
procesar_directorios(_,[])->
	[];
procesar_directorios(Nodo,[Usuario|Resto])->
	{ok,Archivos} = file:list_dir(Nodo++"/"++Usuario),
	[[Usuario]++parsear_archivos(Archivos)] ++ procesar_directorios(Nodo,Resto).


%Dado un nodo y un contenido cambia el contenido de ese nodo
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


%Dado una lista de nodos, se encarga de mandar el mensaje de forma FIFO
enviar_msg_fifo(Lista,_,0,_) ->
	Lista;

enviar_msg_fifo([Head|Resto],Msg,K,Mcast) ->
	[Process,Node,_,_] = Head,
	{mcast,Mcast} ! {unicasts,{Process,Node},Msg},
	enviar_msg_fifo(Resto++[Head],Msg,K-1,Mcast).
	
%Funcion encargada de implementar el algoritmo de grandulon
grandulon([],nil,_) ->
	node();

grandulon([],Minimo,_) ->
	element(2,Minimo);

grandulon([[_,Nodo,Pid,_]|Resto],nil,Mcast) ->
	{Resp,Resp2} = revisar(Mcast,Nodo),
	if
		Resp==undefined orelse Resp2/=true->
			grandulon(Resto,nil,Mcast);
		true-> 
			grandulon(Resto,{Pid,Nodo},Mcast)
	end;

grandulon([[_,Nodo,Pid,_]|Resto],Compare,Mcast) ->
	{Resp,Resp2} = revisar(Mcast,Nodo),
	if
		Resp==undefined orelse Resp2/=true orelse {Pid,Nodo} > Compare ->
			grandulon(Resto,{Pid,Nodo},Mcast)
		;
		true->
			grandulon(Resto,Compare,Mcast)
	end.


%Funcion que dado un usuario y un archivo nuevo, se encarga de agregar
%Ese archivo a las pertenencias del usuario
agregar_al_cliente([],_,_,_)->
	[];
agregar_al_cliente([[Usuario|Resto1]|Resto2],Usuario,Archivo,Etiqueta)->
	Resto3 = lists:delete({Archivo,Etiqueta},Resto1),
	[[Usuario,{Archivo,Etiqueta}]++Resto3] ++ Resto2;
agregar_al_cliente([Head|Resto],Usuario,Archivo,Etiqueta)->
	[Head]++agregar_al_cliente(Resto,Usuario,Archivo,Etiqueta).


%Busca los archivos asosicados a un usuario en un nodo
buscar_lista_usuario(_,[])->
	[];
buscar_lista_usuario(Usuario,[[Usuario|Cont]|_])->
	Cont;

buscar_lista_usuario(Usuario,[_|Resto])->
	buscar_lista_usuario(Usuario,Resto).


%Dada una lista de archivos y el nombre de un archivo 
%indica la version mas actual de ese archivo
mejor_version(_,[],Res)->
	Res;

mejor_version(Archivo,[Head|Resto],Res)->
	{Arch,Version} = Head,
	if
		Arch==Archivo andalso (Res==nil orelse Version>Res)->
			mejor_version(Archivo,Resto,Version);
		true->
			mejor_version(Archivo,Resto,Res)
	end.


%Busca el nodo con la version mas reciente de un archivo especifico
nodo_con_version_mas_reciente(_,_,[],Version,Nodo)->
	{Version,Nodo};

nodo_con_version_mas_reciente(NombreCliente,Archivo,[[_,Nodo,_,Cont]|Resto],MejorVersion,MejorNodo)->
	ListaUser = buscar_lista_usuario(NombreCliente,Cont),
	Version = mejor_version(Archivo,ListaUser,nil),
	if
		Version==nil->
			nodo_con_version_mas_reciente(NombreCliente,Archivo,Resto,MejorVersion,MejorNodo);
		MejorVersion==nil->
			nodo_con_version_mas_reciente(NombreCliente,Archivo,Resto,Version,Nodo);
		{Version,Nodo} > {MejorVersion,MejorNodo}->
			nodo_con_version_mas_reciente(NombreCliente,Archivo,Resto,Version,Nodo);
		true ->
			nodo_con_version_mas_reciente(NombreCliente,Archivo,Resto,MejorVersion,MejorNodo)

	end.	


%La funcion Run Corre el servidor
%Los parametros son
%Principal que es el servidor principal, actual
%Mcast que es la direccion multicat de registro
%Lista que es la Lista de los servidores con sus contenidos
%Clientes que es la lista de clientes 
%Contenido que es el contenido aparte de este servidor
%Red que es la redundancia que existe en el sistema
run(Principal, Mcast,Lista,Clientes,Contenido,Red) ->

	io:format("~nMi lista de servidores ahora es~n~p~n~n",[Lista]),
	io:format("~nY el servidor principal visto desde ~p es: ~n~p~n~n",[node(),Principal]),

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

		{revisen_lista,Lista2} ->
			if
				Lista/=Lista2 ->
					NewLista=Lista2;

				true->
					NewLista = Lista
			end,
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
			{Resp,Resp2} = revisar(Mcast,Principal),

			if

				Resp==undefined orelse Resp2/=true ->
					%Se cayo el servidor principal,
					%Hacer algoritmo del grandulon
					NewS = grandulon(Lista,nil,Mcast),
					{mcast,Mcast} ! {multicasts_cliente, {new_principal,NewS},Clientes},
					{mcast,Mcast} ! {multicasts, {new_princ,NewS}},

					run(NewS, Mcast,Lista,Clientes,Contenido,Red);
				true ->
					ok
		
			end;

		{new_princ,NewServ}->
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido,
			run(NewServ,Mcast,NewLista,NewClientes,NewContenido,Red);
		

		{peticion_agregar_cliente,Nombre,ClienteNuevo} ->
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido,
			{mcast,Mcast} ! {multicasts,{agregar_cliente,Nombre,ClienteNuevo}}
			;

		%Agrega un cliente nuevo al servidor por si luego
		%se cae el servidor principal se envia un msg a cada cliente
		%para que  el servidor actualice a cada cliente con quien es el
		%Principal
		{agregar_cliente,Nombre,ClienteNuevo} ->
			NewLista=Lista,
			NewClientes = Clientes ++ [ClienteNuevo],
			Servi = atom_to_list(node()),
			Condic = filelib:is_dir(Servi++"/"++Nombre),
			if
				not (Condic)->
					NewContenido = Contenido++[[Nombre]],
					{mcast,Mcast} ! {cambio_contenido,{self(),node(),NewContenido}},
					{mcast,Mcast} ! {multicasts,{cambio_contenido,{self(),node(),NewContenido}}}

				;
				true->
					NewContenido = Contenido
			end,
			filelib:ensure_dir(Servi++"/"++Nombre),
			
			%Creo la carpeta correspondiente al repo del cliente si es 
			%necesario
			filelib:ensure_dir(filename:absname("")++"/"++Servi++"/"++Nombre++"/")
			;

		%msg que indica que un cliente quiere ser agregado con lo que 
		%el servidor (se asume que es el principal el que recibe la
		%senial) manda un broadcast mediante el multicast

		{multicast_cliente,Client} ->
			{mcast,Mcast} ! {multicast,{agregar_cliente,Client}},
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido;

		%Aqui se busca la mejor version de un archivo
		{peticion_buscar_archivo,NombreCliente,NodoCliente,Archivo} ->
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido,
			{mcast,Mcast} ! {multicasts,{buscar_archivo,NombreCliente,NodoCliente,Archivo}}
			;


		{buscar_archivo,NombreCliente,NodoCliente,Archivo}->
			{Version,Busqueda} = nodo_con_version_mas_reciente(NombreCliente,Archivo,Lista,nil,nil),
			if
				%Envio el mensaje al cliente si esta este nodo tiene la
				%mejor version
				node()==Busqueda->
					{ok,File} = file:read_file(atom_to_list(node())++"/"++NombreCliente++"/"++Archivo++"_"++Version),
					EnviarCont = unicode:characters_to_list(File),
					{mcast,Mcast} ! {unicasts,{servidor,Principal},{enviar_update,NodoCliente,EnviarCont}};

				%No existe tal archivo en ningun repo
				Busqueda==nil->
					{mcast,Mcast} ! {unicasts,{servidor,Principal},{no_existe,NodoCliente}};

				%Existe una version del archivo, pero esta en otro nodo
				%entonces, no la paso	
				true->
					ok
			end,
			NewClientes = Clientes,
			NewContenido = Contenido,
			NewLista = Lista
			;

		{enviar_update,NodoCliente,Conte}->
			Nod = element(2,NodoCliente),
			
			{cliente,Nod} ! {update,Conte},
			NewClientes = Clientes,
			NewContenido = Contenido,
			NewLista = Lista
			;


		{no_existe,NodoCliente}->
			Nod = element(2,NodoCliente),
			{cliente,Nod} ! no_existe,
			NewClientes = Clientes,
			NewContenido = Contenido,
			NewLista = Lista
		;
		{peticion_agregar_archivo,Cliente,{Arch,Cont}} ->
			Tiempo = integer_to_list(promediacion(Mcast,Lista,0,0,0)),
			NewLista = enviar_msg_fifo(Lista,{add_a,{Cliente,Arch,Cont,Tiempo}},Red+1,Mcast),
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

			
		%Aqui se agregan los archivos realmente, la guardia que esta antes de
		%la anterior a esta solo recibe la peticion del cliente
		{add_a,Tupla} ->
			Cliente=element(1,Tupla),
			Arch2 = element(2,Tupla),
			Arch = string:substr(Arch2,string:rstr(Arch2,"/")+1),
			Cont = element(3,Tupla),
			Tiempo = element(4,Tupla),
			Servi = atom_to_list(node()),
			filelib:ensure_dir(Servi++"/"++Cliente++"/"++Arch++"_"++Tiempo),
			file:write_file(Servi++"/"++Cliente++"/"++Arch++"_"++Tiempo,Cont),
			NewClientes = Clientes,
			Contengo = Contenido,
			NewContenido = agregar_al_cliente(Contengo,Cliente,Arch,Tiempo),
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
			NewLista = multicast:fuera_muertos(Lista,ListaM)
		;	
		_->
			NewLista=Lista,
			NewClientes = Clientes,
			NewContenido = Contenido
			
		after
			500 ->
				NewLista=Lista,
				NewClientes = Clientes,
				NewContenido = Contenido	

	end,
	run(Principal,Mcast,NewLista,NewClientes,NewContenido,Red).



main([Mcast,Principal,K|_]) -> 
	register(servidor,self()),

	
	%Crea el directorio respectivo del servidor
	Servi = atom_to_list(node()),

	filelib:ensure_dir(filename:absname("")++"/"++Servi++"/"),

	%Se asegura de que el directorio exista, es decir lo crea si no esta
	filelib:ensure_dir(Servi),

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
	{ok,ListaActual} = file:list_dir(Servi),
	Content = procesar_directorios(Servi,ListaActual),
	{mcast,Mcast} ! {addme,[servidor,node(),self(),Content]},

	spawn(mitimeout,clock,[{servidor,node()},500,revisar_principal]),

	%El multicast debe contener la lista de servidores
	% que estan comunicados con el multicast
	%Inicialmente esta vacia
	%Y tambien posee la lista de clientes replicadas en cada servidor
	%PD: La lista de servidores tiene [NombreProcess,Nodo,Pid,Contenido]
	 
	run(Principal,Mcast,[],[],Content,Redundancia);

main(_) ->
	io:format("Debe pasar como parametro, la direccion multicast, la direccion del servidor principal, y un numero K que indica la redundancia~n").
