% http://muharem.wordpress.com/2007/08/21/processing-xml-in-erlang/
-module(xml_reader).
 -export([parse/1]).
 -include_lib("xmerl/include/xmerl.hrl").
 
 
 parse(FName) ->

     {R,_} = xmerl_scan:file(FName),
     L = lists:reverse(extract(R, [])),
     L.
 

 extract(R, L) when is_record(R, xmlElement) ->
     case R#xmlElement.name of
         process ->
             lists:foldl(fun extract/2, L, R#xmlElement.content);
         item ->
            ItemData = lists:foldl(fun extract/2, [], R#xmlElement.content),
             [ ItemData | L ];
         _ -> 
             lists:foldl(fun extract/2, L, R#xmlElement.content)
     end;
 
 extract(#xmlText{parents=[{id,_},{process,_},_], value=V}, L) ->
     [{process, V}|L]; 
 
 extract(#xmlText{parents=[{id,_},{item,_},_,_], value=V}, L) ->
     [{id, V}|L];
     
 extract(#xmlText{parents=[{arrival,_},{item,_},_,_], value=V}, L) ->
     [{arrival, V}|L]; 
 
 extract(#xmlText{parents=[{size,_},{item,_},_,_], value=V}, L) ->
     [{size, V}|L];

 extract(#xmlText{parents=[{page,_},{item,_},_,_], value=V}, L) ->
     [{page, V}|L]; 
 
 extract(#xmlText{}, L) -> L.  
 

