-module(dotenv_ffi).
-export([get_env/1, set_env/2]).

get_env(Key) ->
    case os:getenv(binary_to_list(Key)) of
        false -> {error, nil};
        Value -> {ok, list_to_binary(Value)}
    end.

set_env(Key, Value) ->
    os:putenv(binary_to_list(Key), binary_to_list(Value)),
    true.
