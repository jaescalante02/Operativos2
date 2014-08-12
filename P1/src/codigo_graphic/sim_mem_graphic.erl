% En base a lo investigado en http://wxerlang.dougedmunds.com/
-module(sim_mem_graphic).
-export([start/1]).
-include_lib("wx/include/wx.hrl").

-define(COLORES_LIST, [
{0, 69, 206, 69},
{255,127,80, 255},
{238,130,238, 255},
{176,48,96, 255},
{184,134,11, 255},
{0,250,154, 255},
{102,205,170, 255},
{255,228,181, 255},
{25,25,112, 255},
{255,182,193, 255},
{138,43,226, 255}
%{,,, 255},
]).


%
%
%
%
%
dibujar_arbol(Paint, Pen, Brush, _, LeftCorner={_, _}, 
              Tam={ _, _}, {_, nil, _, _, false}, _, _) ->
    wxPen:setColour(Pen, ?wxBLACK),
    wxBrush:setColour(Brush, ?wxWHITE),            
    wxDC:setPen(Paint, Pen), 
    wxDC:setBrush(Paint, Brush),
    wxDC:drawRectangle(Paint, LeftCorner, Tam);

dibujar_arbol(Paint, Pen, Brush, Especial={_, _}, LeftCorner={X, Y}, 
              Tam={W, H}, {_, nil, Izq, Der, true}, vertical, Dic) ->
    
    dibujar_arbol(Paint, Pen, Brush, Especial, {X, Y}, {W div 2, H}, 
                  Izq,  horizontal, Dic),
    dibujar_arbol(Paint, Pen, Brush, Especial, {X+(W div 2), Y}, {W div 2, H}, 
                  Der,  horizontal, Dic),              
    wxPen:setColour(Pen, ?wxBLACK),
    wxBrush:setColour(Brush, {255, 0, 0, 0}),            
    wxDC:setPen(Paint, Pen), 
    wxDC:setBrush(Paint, Brush),
    wxDC:drawRectangle(Paint, LeftCorner, Tam);
    
dibujar_arbol(Paint, Pen, Brush, Especial={ _, _}, LeftCorner={X, Y}, 
              Tam={W, H}, {_, nil, Izq, Der, true}, horizontal, Dic) ->
    
    dibujar_arbol(Paint, Pen, Brush, Especial, {X, Y}, {W, H div 2}, 
                  Izq, vertical, Dic),          
    dibujar_arbol(Paint, Pen, Brush, Especial, {X, Y+(H div 2)}, {W, H div 2}, 
                  Der, vertical, Dic),              
    wxPen:setColour(Pen, ?wxBLACK),
    wxBrush:setColour(Brush, {255, 0, 0, 0}),            
    wxDC:setPen(Paint, Pen), 
    wxDC:setBrush(Paint, Brush),
    wxDC:drawRectangle(Paint,LeftCorner, Tam);    
    
dibujar_arbol(Paint, Pen, Brush, {ID2, Color}, LeftCorner={ _, _}, 
              Tam={W, H}, {TamA, {ID, Pags}, _, _, _}, _, Dic) ->
    if
    (ID==ID2)->          
      wxPen:setColour(Pen, Color),
      wxBrush:setColour(Brush, Color);
    (true)->
      {ok, Owncolor}= dict:find(ID, Dic),
      wxPen:setColour(Pen, Owncolor),
      wxBrush:setColour(Brush, Owncolor) 
    end,               
    wxDC:setPen(Paint, Pen), 
    wxDC:setBrush(Paint, Brush),
    wxDC:drawRectangle(Paint, LeftCorner, {trunc((length(Pags)/TamA)*W), H}),
    wxPen:setColour(Pen, ?wxBLACK),
    wxBrush:setColour(Brush, {255, 0, 0, 0}),            
    wxDC:setPen(Paint, Pen), 
    wxDC:setBrush(Paint, Brush),
    wxDC:drawRectangle(Paint, LeftCorner, Tam).     

%
%
%
%
%
dibujar_leyenda(_, _, _, _, _, [])->ok;
dibujar_leyenda(Paint, Pen, Brush, Font, {X, Y}, [{ID, Color}|Leyenda])->

        wxPen:setColour(Pen, Color),
        wxBrush:setColour(Brush, Color),       
        wxDC:setPen(Paint, Pen), 
        wxDC:setBrush(Paint, Brush),
        wxDC:drawCircle(Paint, {X-9, Y+6}, 3),                                     
        wxDC:drawText(Paint, ID, {X, Y}), 
        dibujar_leyenda(Paint, Pen, Brush, Font,{X,Y+20}, Leyenda). 


%
%
%
%
%
loop(Frame, _, [], _, _) ->

    io:format("Closing window ~n",[]), 
    wxWindow:destroy(Frame),  
    ok;
    
loop(Frame, Panel, [{Action, ID, Arb1} | Arbs], [Color |Colores], Dic) ->

      case Action of
      
        fault->
          NewDic=Dic,
          NewColors= [Color |Colores],
          SpecialColor={255, 0, 0, 255}; 
        load->
          NewDic=Dic,
          NewColors= [Color |Colores],
          SpecialColor={255, 215, 0, 255}; 
        found-> 
          NewDic=Dic,
          NewColors= [Color |Colores],
          SpecialColor={50, 205, 50, 255};
        add->
          NewDic= dict:store(ID, Color, Dic),
          NewColors=Colores,
          SpecialColor=Color;               
        erase->  
          {_, LastColor} = dict:find(ID, Dic),
          NewDic= dict:erase(ID, Dic),
          NewColors= lists:append(Colores, [LastColor]),
          SpecialColor={0, 0, 0, 255}; 
        fail->
          NewDic=Dic,
          NewColors= [Color |Colores],
          SpecialColor=nil;                   
        ok-> 
          NewDic=Dic,
          NewColors= [Color |Colores],
          SpecialColor=nil        
      end,
  
      OnPaint2 = fun(_Evt, _Obj) ->  
                 
        Paint = wxPaintDC:new(Panel),
        Pen = wxPen:new(),
        Brush = wxBrush:new(),
        Font = wxFont:new(8, ?wxFONTFAMILY_MODERN, ?wxFONTSTYLE_NORMAL, 
                          ?wxFONTWEIGHT_BOLD),
                          
        if
          (Action==fail)->
              wxPen:setColour(Pen, ?wxRED),
              wxBrush:setColour(Brush, ?wxRED),           
              wxDC:setPen(Paint, Pen), 
              wxDC:setBrush(Paint, Brush),
              wxDC:drawRectangle(Paint, {40, 40}, {1044, 532});
          (true)->ok
        end,                    
                          
                                          
        wxPen:setColour(Pen, ?wxBLACK),
        wxBrush:setColour(Brush, ?wxWHITE),           
        wxDC:setPen(Paint, Pen), 
        wxDC:setBrush(Paint, Brush), 
        wxDC:setFont(Paint,Font),


        wxDC:drawRectangle(Paint, {50, 50}, {1024, 512}),
        dibujar_arbol(Paint, Pen, Brush, {ID, SpecialColor}, 
                      {50, 50}, {1024, 512}, Arb1, vertical, NewDic),
        dibujar_leyenda(Paint, Pen, Brush, Font, 
                       {1124, 60}, dict:to_list(NewDic)),

        wxFont:destroy(Font),                                                                                                                    
    	  wxPen:destroy(Pen),
    	  wxBrush:destroy(Brush),        	  
        wxPaintDC:destroy(Paint)
      end,

      wxFrame:connect(Panel, paint, [{callback, OnPaint2}]),
      wxFrame:refresh(Frame),
      receive
        {wx,_, {wx_ref,_,wxFrame,[]},[],
        {wxKey,char_hook,_,_,_,_,_,_,_,_,_,_,_}} -> 
          ok
      end,
      loop(Frame, Panel, Arbs, NewColors, NewDic).

%
%
%
%
%
start(Arbs) ->
    Wx = wx:new(),
    Frame = wxFrame:new(Wx, -1, "MEMORIA", [{size, {1300, 650}}]),
    Panel = wxPanel:new(Frame),

    wxFrame:connect(Frame, char_hook),
    wxFrame:connect(Frame, close_window),
    wxFrame:center(Frame),
    wxFrame:show(Frame),
    receive
        {wx,_, {wx_ref,_,wxFrame,[]},[],
        {wxKey,char_hook,_,_,_,_,_,_,_,_,_,_,_}} -> 
          ok
    end,
    loop(Frame, Panel, Arbs, ?COLORES_LIST, dict:new()).    
    
    
    
    
    
        
