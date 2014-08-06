% http://muharem.wordpress.com/2007/08/21/processing-xml-in-erlang/
-module(xml_reader).
 -export([parse/1]).
 -include_lib("xmerl/include/xmerl.hrl").
 
 
 parse(FName) ->
     % parses a single RSS file
     {R,_} = xmerl_scan:file(FName),
     % extract episode ids, publication dates and MP3 URLs
     L = lists:reverse(extract(R, [])),
     % print process id and data for first two episodes
     %io:format("~n>> ~p~n", [element(1,lists:split(3,L))]),
     L.
 
 % handle 'xmlElement' tags
 extract(R, L) when is_record(R, xmlElement) ->
     case R#xmlElement.name of
         process ->
             lists:foldl(fun extract/2, L, R#xmlElement.content);
         item ->
            ItemData = lists:foldl(fun extract/2, [], R#xmlElement.content),
             [ ItemData | L ];
         _ -> % for any other XML elements, simply iterate over children
             lists:foldl(fun extract/2, L, R#xmlElement.content)
     end;
 
 extract(#xmlText{parents=[{id,_},{process,_},_], value=V}, L) ->
     [{process, V}|L]; % extract process/audiocast id
 
 extract(#xmlText{parents=[{id,_},{item,_},_,_], value=V}, L) ->
     [{id, V}|L]; % extract episode id
 
 extract(#xmlText{parents=[{arrival,_},{item,_},_,_], value=V}, L) ->
     [{arrival, V}|L]; % extract episode arrival
 
 extract(#xmlText{parents=[{size,_},{item,_},_,_], value=V}, L) ->
     [{size, V}|L]; % extract episode publication date ('size' tag)

 extract(#xmlText{parents=[{page,_},{item,_},_,_], value=V}, L) ->
     [{page, V}|L]; % extract episode publication date ('dc:date' tag)
 
 extract(#xmlText{}, L) -> L.  % ignore any other text data
 

