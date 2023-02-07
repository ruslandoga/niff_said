const e = @cImport(@cInclude("erl_nif.h"));
const std = @import("std");

var __resource__: *e.ErlNifResourceType = undefined;
const Error = error{FunctionClauseError};
const Resource = struct { value: c_int };

export fn sum(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var a: i32 = get_int(env, argv[0]) catch return e.enif_make_badarg(env);
    var b: i32 = get_int(env, argv[1]) catch return e.enif_make_badarg(env);
    return e.enif_make_int(env, a + b);
}

export fn create0(env: ?*e.ErlNifEnv, _: c_int, _: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var resource: *Resource = alloc_resorce() catch return e.enif_make_badarg(env);
    resource.value = 0;

    var result: e.ERL_NIF_TERM = e.enif_make_resource(env, resource);
    e.enif_release_resource(resource);

    return result;
}

export fn create1(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var value: c_int = get_int(env, argv[0]) catch return e.enif_make_badarg(env);
    var resource: *Resource = alloc_resorce() catch return e.enif_make_badarg(env);
    resource.value = value;

    var result: e.ERL_NIF_TERM = e.enif_make_resource(env, resource);
    e.enif_release_resource(resource);

    return result;
}

export fn fetch(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var resource: *Resource = get_resource(env, argv[0]) catch return e.enif_make_badarg(env);
    return e.enif_make_int(env, resource.value);
}

export fn set(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var resource: *Resource = get_resource(env, argv[0]) catch return e.enif_make_badarg(env);
    var value: c_int = get_int(env, argv[1]) catch return e.enif_make_badarg(env);
    resource.value = value;
    return e.enif_make_atom(env, "ok");
}

fn alloc_resorce() error{OutOfMemory}!*Resource {
    var ptr: *anyopaque = e.enif_alloc_resource(__resource__, @sizeOf(Resource)) orelse return error.OutOfMemory;
    var resource: *Resource = @ptrCast(*Resource, @alignCast(@alignOf(*Resource), ptr));
    return resource;
}

fn get_resource(env: ?*e.ErlNifEnv, term: e.ERL_NIF_TERM) Error!*Resource {
    var ptr: ?*anyopaque = undefined;

    if (e.enif_get_resource(env, term, __resource__, @ptrCast([*c]?*anyopaque, &ptr)) != 1) {
        return Error.FunctionClauseError;
    }

    var resource: *Resource = @ptrCast(*Resource, @alignCast(@alignOf(*Resource), ptr));
    return resource;
}

fn get_int(env: ?*e.ErlNifEnv, term: e.ERL_NIF_TERM) Error!c_int {
    var i: c_int = undefined;
    if (e.enif_get_int(env, term, &i) != 1) return Error.FunctionClauseError;
    return i;
}

var nif_funcs = [_]e.ErlNifFunc{
    e.ErlNifFunc{ .name = "sum", .arity = 2, .fptr = sum, .flags = 0 },
    e.ErlNifFunc{ .name = "create", .arity = 0, .fptr = create0, .flags = 0 },
    e.ErlNifFunc{ .name = "create", .arity = 1, .fptr = create1, .flags = 0 },
    e.ErlNifFunc{ .name = "fetch", .arity = 1, .fptr = fetch, .flags = 0 },
    e.ErlNifFunc{ .name = "set", .arity = 2, .fptr = set, .flags = 0 },
};

export fn nif_load(env: ?*e.ErlNifEnv, _: [*c]?*anyopaque, _: e.ERL_NIF_TERM) c_int {
    var flags: c_uint = e.ERL_NIF_RT_CREATE | e.ERL_NIF_RT_TAKEOVER;
    __resource__ = e.enif_open_resource_type(env, null, "Resource", null, flags, null) orelse unreachable;
    return 0;
}

const entry = e.ErlNifEntry{
    .major = e.ERL_NIF_MAJOR_VERSION,
    .minor = e.ERL_NIF_MINOR_VERSION,
    .name = "Elixir.NiffSaid.Nif",
    .num_of_funcs = nif_funcs.len,
    .funcs = &(nif_funcs[0]),
    .load = &nif_load,
    .reload = null,
    .upgrade = null,
    .unload = null,
    .vm_variant = "beam.vanilla",
    .options = 1,
    .sizeof_ErlNifResourceTypeInit = @sizeOf(e.ErlNifResourceTypeInit),
    .min_erts = "erts-13.0",
};

export fn nif_init() *const e.ErlNifEntry {
    return &entry;
}
