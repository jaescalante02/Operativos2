-module(buddy).
-export([buscar_tam/3,insertar_elem/2,insertar/4,insert/3,eliminar/2]).

%% aqui las tuplas representan un Arbol de la forma 
%%{tamanio,contenido,hijo_izquierdo,hijo_derecho,esta_partido}


buscar_tam(nil,Tam,T) ->
	T>=Tam;

buscar_tam(Arb,Tam,T) ->
	Y=((element(1,Arb)>=Tam) and (nil==element(2,Arb)) and (not element(5,Arb))) orelse ((buscar_tam(element(4,Arb),Tam, T div 2) orelse buscar_tam(element(3,Arb),Tam,T div 2)) andalso element(5,Arb) andalso nil==element(2,Arb)),
	Y.

insertar_elem(Arb,Cont) ->
	{element(1,Arb),Cont,nil,nil,false}.

insertar(nil,_,Cont,64) ->
	{64,Cont,nil, nil, false};

insertar(nil,Tam,Cont,T) ->
	if
		T div 2 >= Tam->
			{T,nil,insertar(nil,bla,Cont,T div 2),nil,true};
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
		true -> io:format("Error~n")
	end.

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
		B==Cont -> 
			nil;
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
				true->
					{A,B,X,Y,false}
			end
	end.

