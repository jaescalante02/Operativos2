-module(cliente).
-export([main/0,main/1,menu/1]).

%Muestra el menu para el usuario
menu(Server) ->
	io:format("Menu del cliente, indique el numero de la opcion deseada:~n"),
	io:format("  1.- Checkout~n"),
	io:format("  2.- Update~n"),
	io:format("  3.- Commit~n"),
	io:format("  4.- Salir~n"),
	Opcion = io:get_line(""),
	io:format("~p~n",[Opcion]),
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
			end,
			menu(NewServer)

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
			end,

			menu(NewServer)
		;
		Opcion=="3\n" ->
			io:format("Introduzca el nombre del archivo que desea realizar la operacion:~n"),
			Arch = io:get_line(""),
			io:format("Opcion 3 ~p~n",[Arch]),
			{servidor,Server} ! {agregar_archivo,{Arch,now()}},
			receive
				{new,NS} ->
					NewServer = NS
			after  
				500 ->
					NewServer = Server
			end,
			menu(NewServer)
		;
		Opcion=="4\n" ->
			io:format("Hasta pronto~n"),
			halt(0)
		;
		true ->
			io:format("Opcion invalida, vuelva a intentar:~n"),
			NewServer=Server,
			menu(NewServer)
	end.




%Proceso principal del cliente

main() ->
	io:format("Debe pasar como parametro el servidor.").

main([Server|_])->
	Conecto = net_kernel:connect_node(Server),
	if
		true/=Conecto ->
			io:format("Fallo al conectar con el servidor.~n"),
			halt(1);
		true ->
			io:format("")
	end,
	%%Logro conectar con el servidor y lanzo el menu para el usuario
	menu(Server).

