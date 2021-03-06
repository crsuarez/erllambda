-module(erllambda_SUITE).

-include_lib("common_test/include/ct.hrl").

%%--------------------------------------------------------------------
%% @spec suite() -> Info
%% Info = [tuple()]
%% @end
%%--------------------------------------------------------------------
suite() ->
    [{timetrap, {seconds, 30}}].

%%--------------------------------------------------------------------
%% @spec init_per_suite(Config0) ->
%%     Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%% Config0 = Config1 = [tuple()]
%% Reason = term()
%% @end
%%--------------------------------------------------------------------
init_per_suite(Config) ->
    {ok, _} = erllambda_aws_runtime:start(),
    Port = erllambda_aws_runtime:http_port(),
    RunTimeAddress = lists:flatten(io_lib:format("127.0.0.1:~w", [Port])),
    OldEnv =
        putenv([{"AWS_LAMBDA_RUNTIME_API", RunTimeAddress},
                {"AWS_ACCESS_KEY_ID", "10560ff7be594e0c"},
                {"AWS_SECRET_ACCESS_KEY", "71b5110832454df0ba9a85073d60bb8b"},
                {"AWS_SESSION_TOKEN", "c14c5ae0d56242cbb2d85a8cf1433ece"}]),
    application:load(erllambda),
    application:set_env(erllambda, handler_module, erllambda_fibonachi_handler),
    application:set_env(erllambda, print_env, false),
    {ok, _} = application:ensure_all_started(erllambda),
    [{old_env, OldEnv} | Config].

%%--------------------------------------------------------------------
%% @spec end_per_suite(Config0) -> term() | {save_config,Config1}
%% Config0 = Config1 = [tuple()]
%% @end
%%--------------------------------------------------------------------
end_per_suite(Config) ->
    application:stop(erllambda),
    putenv(?config(old_env, Config)),
    application:unload(erllambda),
    ok = erllambda_aws_runtime:stop().

%%--------------------------------------------------------------------
%% @spec init_per_group(GroupName, Config0) ->
%%               Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%% GroupName = atom()
%% Config0 = Config1 = [tuple()]
%% Reason = term()
%% @end
%%--------------------------------------------------------------------
init_per_group(_GroupName, Config) ->
    Config.

%%--------------------------------------------------------------------
%% @spec end_per_group(GroupName, Config0) ->
%%               term() | {save_config,Config1}
%% GroupName = atom()
%% Config0 = Config1 = [tuple()]
%% @end
%%--------------------------------------------------------------------
end_per_group(_GroupName, _Config) ->
    ok.

%%--------------------------------------------------------------------
%% @spec init_per_testcase(TestCase, Config0) ->
%%               Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%% TestCase = atom()
%% Config0 = Config1 = [tuple()]
%% Reason = term()
%% @end
%%--------------------------------------------------------------------
init_per_testcase(_TestCase, Config) ->
    Config.

%%--------------------------------------------------------------------
%% @spec end_per_testcase(TestCase, Config0) ->
%%               term() | {save_config,Config1} | {fail,Reason}
%% TestCase = atom()
%% Config0 = Config1 = [tuple()]
%% Reason = term()
%% @end
%%--------------------------------------------------------------------
end_per_testcase(_TestCase, _Config) ->
    ok.

%%--------------------------------------------------------------------
%% @spec groups() -> [Group]
%% Group = {GroupName,Properties,GroupsAndTestCases}
%% GroupName = atom()
%% Properties = [parallel | sequence | Shuffle | {RepeatType,N}]
%% GroupsAndTestCases = [Group | {group,GroupName} | TestCase]
%% TestCase = atom()
%% Shuffle = shuffle | {shuffle,{integer(),integer(),integer()}}
%% RepeatType = repeat | repeat_until_all_ok | repeat_until_all_fail |
%%              repeat_until_any_ok | repeat_until_any_fail
%% N = integer() | forever
%% @end
%%--------------------------------------------------------------------
groups() ->
    [].

%%--------------------------------------------------------------------
%% @spec all() -> GroupsAndTestCases | {skip,Reason}
%% GroupsAndTestCases = [{group,GroupName} | TestCase]
%% GroupName = atom()
%% TestCase = atom()
%% Reason = term()
%% @end
%%--------------------------------------------------------------------
all() ->
    [test_fibonachi].

%%%===================================================================
%%% TestCases
%%%===================================================================

%%--------------------------------------------------------------------
%% @spec TestCase() -> Info
%% Info = [tuple()]
%% @end
%%--------------------------------------------------------------------
test_fibonachi() ->
    [].

%%--------------------------------------------------------------------
%% @spec TestCase(Config0) ->
%%               ok | exit() | {skip,Reason} | {comment,Comment} |
%%               {save_config,Config1} | {skip_and_save,Reason,Config1}
%% Config0 = Config1 = [tuple()]
%% Reason = term()
%% Comment = term()
%% @end
%%--------------------------------------------------------------------
test_fibonachi(_Config) ->
    {ok, #{<<"sequence">> := [0, 1, 1, 2, 3, 5]}} =
        lists:foldl(
          fun(_, {ok, Params}) -> erllambda_aws_runtime:call(Params) end,
          {ok, #{<<"sequence">> => []}},
          lists:seq(0, 5)).


%%%===================================================================
%%% Internal functions
%%%===================================================================

putenv([{Key, Value} | Tail]) ->
    OldValue = os:getenv(Key, undefined),
    putenv(Key, Value),
    [{Key, OldValue} | putenv(Tail)];
putenv([]) ->
    [].

putenv(Key, undefined) ->
    os:unsetenv(Key);
putenv(Key, Value) ->
    os:putenv(Key, Value).
