% Mingfei Yao (my1914)

-module(acceptor).
-export([start/0]).

start() ->
  prepare(-1, sets:new()).

prepare(APN, Accepted) ->
  receive 
    {p1a, Proposer, PN} -> 
      if 
        PN > APN ->
          Proposer ! {p1b, self(), PN, Accepted},
          prepare(PN, Accepted);
        true -> 
          Proposer ! {p1b, self(), APN, Accepted},
          prepare(APN, Accepted)
      end;

    {p2a, Proposer, PN, Slot, Command} ->
      if
        PN == APN -> 
          NewAccepted = sets:add_element({PN, Slot, Command}, Accepted),
          Proposer ! {p2b, self(), APN},
          prepare(APN, NewAccepted);
        true ->
          Proposer ! {p2b, self(), APN},
          prepare(APN, Accepted)
      end
  end.
