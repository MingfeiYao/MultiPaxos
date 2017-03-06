% Mingfei Yao (my1914)
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(replica).
-export([start/1]).

start(Database) ->
  receive
    {bind, Leaders} -> 
       next(Database, Leaders, 1, 1, sets:new(), sets:new(), sets:new())
  end.

next(Database, Leaders, Slot_in, Slot_out, Proposals, Decisions, Requests) ->
  receive
    {request, C} ->      % request from client
      NewRequests = sets:add_element(C, Requests),
      propose(Database, Slot_in, Slot_out, Leaders, sets:to_list(NewRequests), 
                    sets:to_list(Decisions), sets:to_list(Proposals));
    {decision, S, C} ->  % decision from commander
      NewDecisions = sets:add_element({S, C}, Decisions),
      {UpdatedDecisions, NewProposal, NewRequests, NewSlotOut} = decide(Database, sets:to_list(NewDecisions), 
                           Slot_out, sets:to_list(Proposals), sets:to_list(Requests)),
      next(Database, Leaders, Slot_in, NewSlotOut, sets:from_list(NewProposal), 
                        sets:from_list(UpdatedDecisions), sets:from_list(NewRequests))
  end. % receive


propose(Database, Slot_in, Slot_out, Leaders, [], Decisions, Proposals) -> 
  next(Database, Leaders, Slot_in, Slot_out, sets:from_list(Proposals), sets:from_list(Decisions), sets:from_list([]));

propose(Database, Slot_in, Slot_out, Leaders, [ C | Requests ], Decisions, Proposals) ->
  WINDOW = 5,
  if Slot_in < Slot_out + WINDOW ->
    {Slots, _} = lists:unzip(Decisions),
    case lists:member(Slot_in, Slots) of 
      false ->  
        NewProposals = sets:from_list([{Slot_in, C}] ++ Proposals),
        [ Leader ! {propose, Slot_in, C} || Leader <- Leaders ],
        propose(Database, Slot_in+1, Slot_out, Leaders, Requests, Decisions, sets:to_list(NewProposals));
      true -> 
        propose(Database, Slot_in+1, Slot_out, Leaders, Requests, Decisions, Proposals)
    end;
    true -> next(Database, Leaders, Slot_in, Slot_out, sets:from_list(Proposals), 
                         sets:from_list(Decisions), sets:from_list([ C | Requests ]))
  end.
   
decide(Database, [ {S, C} | Decisions], Slot_out, Proposals, Requests) ->
  if S == Slot_out ->
    MatchProposals = [ {SProp, CProp} || {SProp, CProp} <- Proposals, SProp == Slot_out ],
    NewProposals = Proposals -- MatchProposals,
    NewRequests = Requests ++ [ CProp || {_, CProp} <- MatchProposals, CProp =/= C ],
    perform(Database, C, Decisions, Slot_out),
    decide(Database, Decisions, Slot_out+1, NewProposals, NewRequests);
    
    true -> 
      { NewDecisions, NewProposals, NewRequests, NewSlotOut } = decide(Database, Decisions, Slot_out, Proposals, Requests),
      { [{S, C}] ++ NewDecisions, NewProposals, NewRequests, NewSlotOut}
    end;

decide(_, [], Slot_out, Proposals, Requests) ->
  { [], Proposals, Requests, Slot_out}.
      

perform(Database, { _, _, Command}, Decisions, Slot_out) ->
  case slotExists(Slot_out, Decisions) of 
    true ->
      io:format("slotExists\n");
    false ->  
      Database ! {execute, Command}
  end.

slotExists(_, []) ->
  false;

slotExists(Slot_out, [ S | Decisions ]) ->
  if S < Slot_out ->
      true;
     true -> 
       slotExists(Slot_out, Decisions)
  end.
