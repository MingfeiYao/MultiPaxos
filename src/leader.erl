% Mingfei Yao (my1914)

-module(leader).
-export([start/0]).

start() ->
  ProposalNumber = 0,
  Active = false,
  Proposals = sets:new(),
  receive 
    {bind, Acceptors, Replicas} -> 
      spawn(scout, start,[self(), Acceptors, ProposalNumber]),
      receiveMessage(Acceptors, Replicas, ProposalNumber, Active, Proposals)
  end.

receiveMessage(Acceptors, Replicas, ProposalNumber, Active, Proposals) ->

  receive
    {propose, Slot, Command} -> 
      case checkSlot(Slot, sets:to_list(Proposals)) of
        false -> 
          NewProposals = sets:add_element({Slot, Command}, Proposals),
          if Active -> 
              spawn(commander, start, 
                [self(), Acceptors, Replicas, ProposalNumber, Slot, Command]);
            true -> ok
          end,
          receiveMessage(Acceptors, Replicas, ProposalNumber, Active, NewProposals);
        true ->
          receiveMessage(Acceptors, Replicas, ProposalNumber, Active, Proposals)
      end;
     {adopted, _, PVal} ->
       NewProposals = updateCommand(sets:to_list(Proposals), sets:to_list(PVal)),
       [ spawn(commander, start, 
          [self(), Acceptors, Replicas, ProposalNumber, Slot, Command]) 
          || {Slot, Command} <- NewProposals ],
       receiveMessage(Acceptors, Replicas, ProposalNumber, true, sets:from_list(NewProposals));
     {preempted, R} -> 
       if R > ProposalNumber ->
           spawn(scout, start, [self(), Acceptors, ProposalNumber+1]),
           receiveMessage(Acceptors, Replicas, ProposalNumber+1, false, Proposals);
         true -> 
           receiveMessage(Acceptors, Replicas, ProposalNumber, Active, Proposals)
       end
       
  end.

checkSlot(_, []) ->
  false;

checkSlot(Slot, [{S, _} | Tail]) ->
  if 
    Slot == S ->
      true;
    true ->
      checkSlot(Slot, Tail)
  end.

updateCommand([ {S, C} | Commands ], PVal) ->
  NewC = pmax(-1, C, PVal, S),
  [{S, NewC}] ++ updateCommand(Commands, PVal);

updateCommand([], _) ->
  [].

pmax(Seen, Command, [{PN, S_, C} | Tail], S) ->
  if S == S_ ->
      if PN < Seen ->
          pmax(Seen, Command, Tail, S);
        true ->
          pmax(PN, C, Tail, S)
      end;
    true ->
      pmax(Seen, Command, Tail, S)
  end;

pmax(_, Command, [], _) ->
  Command.