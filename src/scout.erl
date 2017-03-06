% Mingfei Yao (my1914)

-module(scout).
-export([start/3]).

start(Leader, Acceptors, PN) ->
  [ Acceptor ! {p1a, self(), PN} || Acceptor <- Acceptors ],
  receiveResponse(Leader, sets:from_list(Acceptors), PN, sets:new(), Acceptors).

receiveResponse(Leader, WaitFor, PN, Pvalues, Acceptors) ->
  receive
    {p1b, Acceptor, APN, R} -> 
      if APN == PN -> 
        NewPvalues = sets:union(R, Pvalues),
        NewWait = sets:del_element(Acceptor, WaitFor),
        case sets:size(NewWait) < length(Acceptors)/2 of
          true ->
            Leader ! {adopted, PN, NewPvalues},
            exit(0);
          false -> 
            receiveResponse(Leader, NewWait, PN, NewPvalues, Acceptors)
        end;
        
        true -> 
          Leader ! {preempted, APN},
          exit(0)
      end
 end.
