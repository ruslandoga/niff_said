#include <erl_nif.h>

ErlNifResourceType* RESOURCE_TYPE;

typedef struct {
  int value;
} Resource;

ERL_NIF_TERM sum(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  int a, b;
  enif_get_int(env, argv[0], &a);
  enif_get_int(env, argv[1], &b);
  return enif_make_int(env, a + b);
}

ERL_NIF_TERM create0(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM result;

  Resource* resource = enif_alloc_resource(RESOURCE_TYPE, sizeof(Resource));
  resource->value = 0;

  result = enif_make_resource(env, resource);
  enif_release_resource(resource);

  return enif_make_tuple2(env, enif_make_atom(env, "ok"), result);
}

ERL_NIF_TERM create1(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  ERL_NIF_TERM result;
  unsigned int a;

  if (!enif_get_uint(env, argv[0], &a)) {
    return enif_make_badarg(env);
  }

  Resource* resource = enif_alloc_resource(RESOURCE_TYPE, sizeof(Resource));
  resource->value = a;

  result = enif_make_resource(env, resource);
  enif_release_resource(resource);

  return enif_make_tuple2(env, enif_make_atom(env, "ok"), result);
}

ERL_NIF_TERM fetch(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  Resource* resource;

  if (!enif_get_resource(env, argv[0], RESOURCE_TYPE, (void**)&resource)) {
    return enif_make_badarg(env);
  }

  return enif_make_uint(env, resource->value);
}

ERL_NIF_TERM set(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  Resource* resource;
  unsigned int a;

  if (!enif_get_resource(env, argv[0], RESOURCE_TYPE, (void**)&resource)) {
    return enif_make_badarg(env);
  }

  if (!enif_get_uint(env, argv[1], &a)) {
    return enif_make_badarg(env);
  }

  resource->value = a;
  return enif_make_atom(env, "ok");
}

static ErlNifFunc nif_funcs[] = {{"sum", 2, sum},
                                 {"create", 0, create0},
                                 {"create", 1, create1},
                                 {"fetch", 1, fetch},
                                 {"set", 2, set}};

static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info) {
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  RESOURCE_TYPE =
      enif_open_resource_type(env, "nif", "Resource", NULL, flags, NULL);
  return 0;
}

ERL_NIF_INIT(Elixir.NiffSaid.Nif, nif_funcs, &load, NULL, NULL, NULL);
