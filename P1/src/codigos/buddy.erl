-module(buddy).
-export([buscar_tam/3,insertar_elem/2,insertar/4,insert/3,eliminar/2,
		 esta_proc/2,esta_en_lista/2,esta_cargada/3,tam_l/1,ext/2,
		 modificar_lista/3,lista_de_proc/2,fragmentacion_interna/1,crear_arbol/1,
		 cambiar_priori/3,quitar_elem/2]).

%% aqui las tuplas representan un Arbol de la forma 
%%{tamanio,{id,contenido(que es una lista)},hijo_izquierdo,hijo_derecho,esta_partido}


buscar_tam(nil,Tam,T) ->
	false;

buscar_tam(Arb,Tam,T) ->
	Y=((element(1,Arb)>=Tam) and (nil==element(2,Arb)) and (not element(5,Arb))) orelse ((buscar_tam(element(4,Arb),Tam, T div 2) orelse buscar_tam(element(3,Arb),Tam,T div 2)) andalso element(5,Arb) andalso nil==element(2,Arb)),
	Y.

insertar_elem(Arb,Cont) ->
	{element(1,Arb),Cont,nil,nil,false}.

insertar(nil,_,Cont,1) ->
	{1,Cont,nil, nil, false};

insertar(nil,Tam,Cont,T) ->
	if
		T div 2 >= Tam->
			{T,nil,insertar(nil,Tam,Cont,T div 2),nil,true};
		true ->
			{T,Cont,nil,nil,false}
	end;

insertar(Arb,Tam,Cont, T) -> 
	A = element(1,Arb),
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),
	E = element(5,Arb),
	P = buscar_tam(C,Tam, T div 2),
	Q = buscar_tam(D,Tam,T div 2 ),
	if
		P ->
			{A,B,insertar(C,Tam,Cont,T div 2),D,true}
		;
		Q ->
			{A,B,C,insertar(D,Tam,Cont, T div 2),true}
		;

		B==nil andalso not E->
			insertar_elem(Arb,Cont)
		;
		true ->
            fail
	end.


%%esta es la funcion real de insercion, las demas son auxiliares de esta.
%% se debe llamar con los parametros Arbol, tamanio_buscado, Contenido_a_insertar
insert(A,B,C) ->
	insertar(A,B,C,element(1,A)).

eliminar(nil,_)->
	nil;

eliminar(Arb,Cont) ->
	A = element(1,Arb),
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),

	if
		B/= nil andalso Cont==element(1,B) -> 
			{A,nil,C,D,false};
		true ->	
			X = eliminar(C,Cont),
			Y = eliminar(D,Cont),
			if
				X /= nil andalso Y/= nil andalso element(2,X)==nil andalso element(2,Y)==nil->
					{A,nil,nil,nil,false}
				;
				X==nil andalso Y/=nil andalso element(2,Y)==nil andalso element(5,Y)==false->
					
					{A,nil,nil,nil,false};
				Y==nil andalso X/=nil andalso element(2,X)==nil andalso element(5,X)==false->
					{A,nil,nil,nil,false};
				X/=nil orelse Y/=nil->
					{A,B,X,Y,true};
				true->
					{A,B,X,Y,false}
			end
	end.



%Indica si hay un proceso con id Id en el arbol
esta_proc(nil,_) ->
	false;

esta_proc(Arb,Id) ->
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),
	(B/=nil andalso element(1,B)==Id) or (C/=nil andalso esta_proc(C,Id)) or
	(D/=nil andalso esta_proc(D,Id)).


%verifica si un elemento esta en lista
esta_en_lista([],_) ->
	false;
esta_en_lista([X|Y],El) ->
	(X==El) orelse esta_en_lista(Y,El).


%Indica si una pagina del proceso de id Id 
%tiene cargada la pagina numero N del proceso

esta_cargada(nil,_,_) ->
	false;

esta_cargada(Arb,Id,N) ->
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),
	(B/=nil andalso element(1,B)==Id andalso esta_en_lista(element(2,B),N)) 
	orelse esta_cargada(C,Id,N) orelse esta_cargada(D,Id,N).



%Funcion que quita cierto elemento de una lista
quitar_elem([],_)->
	[];
quitar_elem([N|Y],N)->
	Y;
quitar_elem([X|Y],N)->
	[X]++quitar_elem(Y,N).

%funcion que coloca un elemento (pagina) de una lista del procedo de id Id,
%de ultimo en la lista

cambiar_priori(nil,_,_) ->
	nil;

cambiar_priori(Arb,Id,N) ->
	A = element(1,Arb),
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),
	E = element(5,Arb),
	if
		B/=nil andalso element(1,B)==Id ->
			{A,{Id,[N]++quitar_elem(element(2,B),N)},C,D,E};	
		true ->
			{A,B,cambiar_priori(C,Id,N),cambiar_priori(D,Id,N),E}
	end.


%Da el tamanio de una lista
tam_l([]) ->
	0;
tam_l([_|Y]) ->
	1+tam_l(Y).

%Extraer los primeros K o menos elementos de una lista
ext([],_) ->
	[];
ext([X|Y],N) ->
	if 
		N=<0 ->
			[];
		true->
			[X]++ext(Y,N-1)
	end.



%%Funcion que inserta un conjunto de elementos en una lista 
%%lista que simula las paginas cargadas de un proceso
%Id es el id del proceso a buscar
%L es la lista cuyos elementos se quieren agregar

modificar_lista(nil,_,_) ->
	nil;

modificar_lista(Arb,Id,L) ->
	A = element(1,Arb),
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),
	E = element(5,Arb),
	if
		B/=nil andalso element(1,B)==Id->
			{A,{Id,L++ext(element(2,B),tam_l(element(2,B))-tam_l(L))},C,D,E};
		true ->
			{A,B,modificar_lista(C,Id,L),modificar_lista(D,Id,L),E}
	end.

%Funcion que retorna la lista del proceso con id Id del
%Arbol arb
lista_de_proc(nil,_) ->
	nil;

lista_de_proc(Arb,Id) ->
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),
	if 
		B/=nil andalso element(1,B)==Id ->
			element(2,B);
		true->
			L = lista_de_proc(C,Id),
			R = lista_de_proc(D,Id),
			if
				L /= nil->
					L;
				R /= nil->
					R;
				true->
					nil
		end
	end.
	

fragmentacion_interna(nil) ->
	0;
fragmentacion_interna(Arb) ->
	A = element(1,Arb),
	B = element(2,Arb),
	C = element(3,Arb),
	D = element(4,Arb),
	if 
		B /= nil->
			A-tam_l(element(2,B));
		true->
			fragmentacion_interna(C)+fragmentacion_interna(D)
	end.

crear_arbol(N) ->
	{N,nil,nil,nil,false}.
