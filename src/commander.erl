% Mingfei Yao (my1914)

-module(commander).
-export([start/6]).

start(Leader, Acceptors, Replicas, PN, Slot, Command) ->
  % Broadcast to all acceptors for p2a phase
  [ Acceptor ! {p2a, self(), PN, Slot, Command} || Acceptor <- Acceptors],
  waitMessage(Leader, sets:from_list(Acceptors), Replicas, PN, Slot, Command, Acceptors).

waitMessage(Leader, WaitFor, Replicas, PN, Slot, Command, Acceptors) ->
  receive
    % Receive p2b response from acceptors
    {p2b, A, PN_new} ->
      if PN_new == PN ->
        NewWait = sets:del_element(A, WaitFor),
        case sets:size(NewWait) < length(Acceptors)/2 of
          % Majortiy agree
          true -> [ Replica ! {decision, Slot, Command} || Replica <- Replicas ],
                  exit(0);
          false -> 
            waitMessage(Leader, NewWait, Replicas, PN, Slot, Command, Acceptors)
        end;
        true ->
          % Notify leaders
          Leader ! {preempted, PN_new},
          exit(0)
      end
  end.
