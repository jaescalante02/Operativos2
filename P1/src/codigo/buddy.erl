% Implementacion del BuddySystem con arbol binario

-module(buddy).
-export([buscar_tam/3,insertar_elem/2,insertar/4,insert/3,eliminar/2,
		 esta_proc/2,esta_en_lista/2,esta_cargada/3,tam_l/1,ext/2,
		 modificar_lista/3,lista_de_proc/2,fragmentacion_interna/1,crear_arbol/1,
		 cambiar_priori/3,quitar_elem/2]).

%% aqui las tuplas representan un Arbol de la forma 
%%{tamanio,{id,contenido(que es una lista)},hijo_izquierdo,hijo_derecho,esta_partido}


%Indica si hay un proceso con id Id en Arbol
esta_proc(nil,_) ->
	false;

%Si no es este nodo, entonces capaz sea alguno de los 
%Arboles hijos
esta_proc(Arbol,Id) ->
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	(Tupla/=nil andalso element(1,Tupla)==Id) or 
			esta_proc(Hijo_izq,Id) or esta_proc(Hijo_der,Id).


%verifica si un elemento esta en lista
esta_en_lista([],_) ->
	false;
esta_en_lista([Inicio|Resto],Elemento) ->
	(Inicio==Elemento) orelse esta_en_lista(Resto,Elemento).



%Indica si en un Arbol una pagina del proceso de id Id 
%tiene cargada la pagina numero N del proceso

esta_cargada(nil,_,_) ->
	false;

esta_cargada(Arbol,Id,Pagina) ->
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	(Tupla/=nil andalso element(1,Tupla)==Id andalso esta_en_lista(element(2,Tupla),Pagina)) 
	orelse esta_cargada(Hijo_izq,Id,Pagina) 
	orelse esta_cargada(Hijo_der,Id,Pagina).



%Funcion que quita cierto elemento de una lista
%Caso base, el elemento no existia en la lista
quitar_elem([],_)->
	[];

%El elemento existe en la lista, asi que retorno el resto 
%%para que se concatene con las llamadas anteriores
quitar_elem([Elemento|Lista],Elemento)->
	Lista;

%Caso en el que el inicio de la lista difiere del elemento buscado
quitar_elem([Elemento1|Lista],Elemento)->
	[Elemento1]++quitar_elem(Lista,Elemento).



%funcion que coloca un elemento (pagina) de una lista del procedo de id Id,
%de ultimo en la lista con el fin de mejorar su prioridad en esa lista

cambiar_priori(nil,_,_) ->
	nil;

cambiar_priori(Arbol,Id,Pagina) ->
	Tamanio = element(1,Arbol),
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	Partido = element(5,Arbol),
	if
		Tupla/=nil andalso element(1,Tupla)==Id ->
			{Tamanio,{Id,[Pagina]++quitar_elem(element(2,Tupla),Pagina)},Hijo_izq,Hijo_der,Partido};	
		true ->
			{Tamanio,Tupla,cambiar_priori(Hijo_izq,Id,Pagina),cambiar_priori(Hijo_der,Id,Pagina),Partido}
	end.


%Da el tamanio de una lista
tam_l([]) ->
	0;
tam_l([_|Resto]) ->
	1+tam_l(Resto).


%Extraer los primeros K o menos elementos de una lista
ext([],_) ->
	[];
ext([Elemento|Resto],K) ->
	if 
		K=<0 ->
			[];
		true->
			[Elemento]++ext(Resto,K-1)
	end.



%%Funcion que inserta un conjunto de elementos en una lista 
%%lista que simula las paginas cargadas de un proceso
%Id es el id del proceso a buscar
%Lista es la lista cuyos elementos se quieren agregar

modificar_lista(nil,_,_) ->
	nil;

modificar_lista(Arbol,Id,Lista) ->
	Tamanio = element(1,Arbol),
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	Partido = element(5,Arbol),

	%Si esta es la tupla cuyo proceso es de id = Id entonces 
	%es aqui donde modifico la lista de pagina de ese proceso
	if
		Tupla/=nil andalso element(1,Tupla)==Id->
			{Tamanio,{Id,Lista++ext(element(2,Tupla),tam_l(element(2,Tupla))-tam_l(Lista))},Hijo_izq,Hijo_der,Partido};
		true ->
			{Tamanio,Tupla,modificar_lista(Hijo_izq,Id,Lista),modificar_lista(Hijo_der,Id,Lista),Partido}
	end.


%Funcion que retorna la lista del proceso con id Id del
%Arbol arb
lista_de_proc(nil,_) ->
	nil;

lista_de_proc(Arbol,Id) ->
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	if 
		Tupla/=nil andalso element(1,Tupla)==Id ->
			element(2,Tupla);
		true->
			Lista_izq = lista_de_proc(Hijo_izq,Id),
			Lista_der = lista_de_proc(Hijo_der,Id),
			if
				Lista_izq /= nil->
					Lista_izq;
				Lista_der /= nil->
					Lista_der;
				true->
					nil
		end
	end.
	

%Funcion que cuenta la cantidad de fragmentacion interna en toda la memoria

fragmentacion_interna(nil) ->
	0;
fragmentacion_interna(Arbol) ->
	Tamanio = element(1,Arbol),
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	%resiva si este bloque esta asignado
	%si no lo esta entonces su fragmentacion interna es la suma 
	%de la fragmentacion de sus hijos
	if 
		Tupla /= nil->
			Tamanio-tam_l(element(2,Tupla));
		true->
			fragmentacion_interna(Hijo_izq)+fragmentacion_interna(Hijo_der)
	end.

%Regresa un arbol vacio cuyo tamanio es N
crear_arbol(N) ->
	{N,nil,nil,nil,false}.


%Elimina un proceso con id Id del arbol y si existe lo eliminar y
%hace el merge
eliminar(nil,_)->
	nil;
eliminar(Arbol,Id) ->
	Tamanio = element(1,Arbol),
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	Partido = element(5,Arbol),
	if
		%Si este es el nodo que deseo borrar, borro el contenido
		Tupla /= nil andalso element(1,Tupla)==Id ->
			{Tamanio,nil,nil,nil,false};
		true ->
			%si no estaba en este nodo, posiblemente este en alguno
			%de sus hijos por lo que agarro el resultado de eliminar
			%en ellos y hago merge
			Elimino_izq = eliminar(Hijo_izq,Id),
			Elimino_der = eliminar(Hijo_der,Id),
			if
				%Si mis dos hijos son no tienen nada asignado
				%y no estan partidos hago merge
				 Elimino_izq /= nil andalso Elimino_der/= nil andalso element(2,Elimino_izq)==nil andalso element(2,Elimino_der)==nil andalso element(5,Elimino_der)==false andalso element(5,Elimino_izq)==false->
				 	{Tamanio,nil,nil,nil,false};

				%sino, no puedo hacer merge
				
				true ->
					{Tamanio,Tupla,Elimino_izq,Elimino_der,Partido}
			end
	end.


%Procedimiento que busca si un tamanio a buscar esta disponible (libre)
%En el arbol
buscar_tam(nil,_,_) ->
	false;
buscar_tam(Arbol,Tamanio_buscado,Tamanio_actual) ->
	Tamanio = element(1,Arbol),
	Tupla = element(2,Arbol),
	Hijo_izq = element(3,Arbol),
	Hijo_der = element(4,Arbol),
	Partido = element(5,Arbol),
	Puedo_izq = buscar_tam(Hijo_izq,Tamanio_buscado,Tamanio_actual div 2),
	Puedo_der = buscar_tam(Hijo_der,Tamanio_buscado,Tamanio_actual div 2),
 
	if
		%Si cabe en este nodo, y este nodo no esta partido, ni asignado
		%Entonces esta disponible y cabe el tamanio buscado
		Tamanio>=Tamanio_buscado andalso (not Partido) andalso Tupla==nil->
			true;

		%Sino, si cabe en su hijo izquierdo, entonces se puede
		Puedo_izq ->
			true;

		%Sino, en el derecho
		Puedo_der ->
			true;


		%Si no se puede en ninguna de las opciones anteriores entonces no se puede
		true->
			false
	end.


%Funcion que regresa un Arbol con Contenido insertado
insertar_elem(Arbol,Contenido) ->
	Tamanio = element(1,Arbol),
	{Tamanio,Contenido,nil,nil,false}.

insertar(_,_,Contenido,1)->
	{1,Contenido,nil,nil,false};

insertar(nil,Tamanio_buscado,Contenido,Tamanio_arbol) ->
	if
		Tamanio_arbol div 2 >= Tamanio_buscado ->
			{Tamanio_arbol,nil,insertar(nil,Tamanio_buscado,Contenido,Tamanio_arbol div 2),{Tamanio_arbol div 2,nil,nil,nil,false},true};
		true ->
			{Tamanio_arbol,Contenido,nil,nil,false}

	end;

insertar(Arbol,Tamanio_buscado,Contenido,Tamanio_arbol) ->
		Tamanio = element(1,Arbol),
		Tupla = element(2,Arbol),
		Hijo_izq = element(3,Arbol),
		Hijo_der = element(4,Arbol),
		Partido = element(5,Arbol),
		Puedo_izq = buscar_tam(Hijo_izq,Tamanio_buscado,Tamanio_arbol div 2),
		Puedo_der = buscar_tam(Hijo_der,Tamanio_buscado,Tamanio_arbol div 2),
		
		if 
			Hijo_izq==nil andalso Hijo_der==nil ->
				%si este nodo no tiene hijos, puede que lo divida o no
				%%voy a crear este mismo nodo pero con el contenido
				%%o capaz lo divido si es posible asi que llamo al otro insertar
				%%se que aqui voy a poder agregarlo gracias a los buscar_tam anteriores
				insertar(nil,Tamanio_buscado,Contenido,Tamanio_arbol)		
			;
			Puedo_izq->
				{Tamanio,Tupla,insertar(Hijo_izq,Tamanio_buscado,Contenido,Tamanio_arbol div 2),Hijo_der,Partido}
			;
			Puedo_der->
				{Tamanio,Tupla,Hijo_izq,insertar(Hijo_der,Tamanio_buscado,Contenido,Tamanio_arbol div 2),Partido}
		end.


insert(Arbol,Tamanio_buscado,Contenido) ->
	Tamanio_arbol = element(1,Arbol),

	%Variable que indicara hay un tamanio disponible en el arbol para insertar
	Puedo_insertar = buscar_tam(Arbol,Tamanio_buscado,Tamanio_arbol),

	if
		%Si hay tamanio para insertar, retorno el nuevo arbol, donde 
		%Esta insertado el nuevo proc
		Puedo_insertar ->

			insertar(Arbol,Tamanio_buscado,Contenido,Tamanio_arbol);
		
		%Si no puede insertar en el arbol, retorna fail	
		true -> 
			fail
	end.
