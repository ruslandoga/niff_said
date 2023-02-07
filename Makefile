ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)

all:
	zig build-lib -fPIC -I"$(ERLANG_PATH)" -dynamic -fallow-shlib-undefined -O ReleaseSafe nif/nif.zig
	mv libnif.dylib priv/nif.so

clean:
	rm  -r priv/nif.so
	rm *.dylib
	rm *.dylib.o
