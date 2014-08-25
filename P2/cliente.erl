-module(cliente).
-export([main/0,main/1,menu/2]).

%Muestra el menu para el usuario
menu(Cliente,Server) ->
	io:format("Menu del cliente, indique el numero de la opcion deseada:~n"),
	io:format("  1.- Checkout~n"),
	io:format("  2.- Update~n"),
	io:format("  3.- Commit~n"),
	io:format("  4.- Salir~n"),
	Opcion = io:get_line(""),
	%io:format("~p~n",[Opcion]),
	%Espera a ver si hubo un cambio de servidor principal durante medio segundo
	if
		Opcion=="1\n" ->
			io:format("Introduzca el nombre del archivo que desea realizar la operacion:~n"),
			Arch = io:get_line(""),
			io:format("Opcion 1 ~p~n",[Arch]),
			%%Se realizan las operaciones y luego sigo atendiendo
			receive
				{new,NS} ->
					NewServer = NS
			after  
				500 ->
					NewServer = Server
			end

		;
		Opcion=="2\n" ->
			io:format("Introduzca el nombre del archivo que desea realizar la operacion:~n"),
			Arch = io:get_line(""),
			io:format("Opcion 2 ~p~n",[Arch]),
			receive
				{new,NS} ->
					NewServer = NS
			after  
				500 ->
					NewServer = Server
			end

		;
		Opcion=="3\n" ->
			io:format("Introduzca el nombre del archivo que desea realizar la operacion (introduzca la ruta relativa al directorio actual):~n"),
			Arch = io:get_line(""),
			SZ = string:len(Arch),
			if
				SZ=<2 ->
					Arch2 = Arch;
				true->
					Arch2 = string:substr(Arch,1,SZ-1)
			end,
			io:format("~p~n~n",[Arch2]),
			EsArchivo = filelib:is_file(Arch2) andalso not(filelib:is_dir(Arch2)),
			if
				EsArchivo->
				
				{ok,File} = file:read_file(Arch2),
				Contenido = unicode:characters_to_list(File),
				io:format("Contenido: ~p~n",[Contenido]),
				{servidor,Server} ! {peticion_agregar_archivo,Cliente,{Arch2,Contenido}},
					receive
						{new,NS} ->
							NewServer = NS
					after  
						500 ->
							NewServer = Server
					end;
				true->
						io:format("Introduzca un archivo valido."),
						NewServer=Server
			end
		;
		Opcion=="4\n" ->
			NewServer=Server,
			io:format("Hasta pronto~n"),
			halt(0)
		;
		true ->
			io:format("Opcion invalida, vuelva a intentar:~n"),
			NewServer=Server
		end,
		menu(Cliente,NewServer).




%Proceso principal del cliente

main() ->
	io:format("Debe pasar como parametro el nombre del usuario y el servidor al que desea conectarse (el principal).").

main([Cliente,Server|_])->
	Conecto = net_kernel:connect_node(Server),
	if
		true/=Conecto ->
			io:format("Fallo al conectar con el servidor.~n"),
			halt(1);
		true ->
			io:format("")
	end,
	NombreCliente = atom_to_list(Cliente),
	{servidor,Server} ! {peticion_agregar_cliente,NombreCliente,{self(),node()}},
	%%Logro conectar con el servidor y lanzo el menu para el usuario
	menu(NombreCliente,Server);
	
main(_) ->
	io:format("Debe pasar como parametro el nombre del usuario y el servidor al que desea conectarse (el principal).").

