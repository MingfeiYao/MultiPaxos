# Distributed coursework
# Mingfei Yao (my1914)

MODULES = system database server client acceptor scout commander leader replica

# Build

ERLC 	= erlc -o ebin

ebin/%.beam: %.erl
	$(ERLC) $<

all:	ebin ${MODULES:%=ebin/%.beam}

ebin: 
	mkdir ebin

.PHONY: clean
clean: 
	rm -f ebin/* erl_crash.dump

# Run

SYSTEM	= system
L_ERL	= erl -noshell -pa ebin -setcookie pass

run:	all
	$(L_ERL) -s $(SYSTEM) start
