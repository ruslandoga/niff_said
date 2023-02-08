const e = @cImport(@cInclude("erl_nif.h"));
const std = @import("std");

var __resource__: *e.ErlNifResourceType = undefined;
const Error = error{BadArgument};
const Resource = struct { value: c_int };

export fn sum(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var a: i32 = get_int(env, argv[0]) catch return e.enif_make_badarg(env);
    var b: i32 = get_int(env, argv[1]) catch return e.enif_make_badarg(env);
    return e.enif_make_int(env, a + b);
}

export fn create0(env: ?*e.ErlNifEnv, _: c_int, _: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    return create_resource(Resource, env, __resource__, Resource{ .value = 0 }) catch return e.enif_make_badarg(env);
}

export fn create1(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var value: c_int = get_int(env, argv[0]) catch return e.enif_make_badarg(env);
    return create_resource(Resource, env, __resource__, Resource{ .value = value }) catch return e.enif_make_badarg(env);
}

export fn fetch(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var resource: *Resource = get_resource(Resource, env, __resource__, argv[0]) catch return e.enif_make_badarg(env);
    return e.enif_make_int(env, resource.value);
}

export fn set(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var resource: *Resource = get_resource(Resource, env, __resource__, argv[0]) catch return e.enif_make_badarg(env);
    var value: c_int = get_int(env, argv[1]) catch return e.enif_make_badarg(env);
    resource.value = value;
    return e.enif_make_atom(env, "ok");
}

export fn fast_compare(env: ?*e.ErlNifEnv, _: c_int, argv: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    var a: c_int = get_int(env, argv[0]) catch return e.enif_make_badarg(env);
    var b: c_int = get_int(env, argv[1]) catch return e.enif_make_badarg(env);
    return e.enif_make_int(env, if (a == b) 0 else if (a < b) -1 else 1);
}

export fn hello(env: ?*e.ErlNifEnv, _: c_int, _: [*c]const e.ERL_NIF_TERM) e.ERL_NIF_TERM {
    return e.enif_make_string(env, "Hello, world!", e.ERL_NIF_LATIN1);
}

fn create_resource(comptime T: type, env: ?*e.ErlNifEnv, resource_type: *e.ErlNifResourceType, value: T) error{OutOfMemory}!e.ERL_NIF_TERM {
    var ptr: *anyopaque = e.enif_alloc_resource(resource_type, @sizeOf(T)) orelse return error.OutOfMemory;
    var obj: *T = @ptrCast(*T, @alignCast(@alignOf(*T), ptr));
    obj.* = value;
    var resource: e.ERL_NIF_TERM = e.enif_make_resource(env, ptr);
    e.enif_release_resource(ptr);
    return resource;
}

fn get_resource(comptime T: type, env: ?*e.ErlNifEnv, resource_type: *e.ErlNifResourceType, term: e.ERL_NIF_TERM) Error!*T {
    var ptr: ?*anyopaque = undefined;
    if (e.enif_get_resource(env, term, resource_type, @ptrCast([*c]?*anyopaque, &ptr)) == 0) return Error.BadArgument;
    return @ptrCast(*T, @alignCast(@alignOf(*T), ptr));
}

fn get_int(env: ?*e.ErlNifEnv, term: e.ERL_NIF_TERM) Error!c_int {
    var i: c_int = undefined;
    if (e.enif_get_int(env, term, &i) == 0) return Error.BadArgument;
    return i;
}

var nif_funcs = [_]e.ErlNifFunc{
    e.ErlNifFunc{ .name = "sum", .arity = 2, .fptr = sum, .flags = 0 },
    e.ErlNifFunc{ .name = "create", .arity = 0, .fptr = create0, .flags = 0 },
    e.ErlNifFunc{ .name = "create", .arity = 1, .fptr = create1, .flags = 0 },
    e.ErlNifFunc{ .name = "fetch", .arity = 1, .fptr = fetch, .flags = 0 },
    e.ErlNifFunc{ .name = "set", .arity = 2, .fptr = set, .flags = 0 },
    e.ErlNifFunc{ .name = "fast_compare", .arity = 2, .fptr = fast_compare, .flags = 0 },
    e.ErlNifFunc{ .name = "hello", .arity = 0, .fptr = hello, .flags = 0 },
};

export fn nif_load(env: ?*e.ErlNifEnv, _: [*c]?*anyopaque, _: e.ERL_NIF_TERM) c_int {
    var flags: c_uint = e.ERL_NIF_RT_CREATE | e.ERL_NIF_RT_TAKEOVER;
    // TODO destructor
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
