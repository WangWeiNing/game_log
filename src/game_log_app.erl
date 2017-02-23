-module(game_log_app).

-behaviour(application).

%% API
-export([start/0]).

%% Application callbacks
-export([start/2, stop/1]).

-export([test/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start() ->
    ok = application:start(crypto),
    ok = application:start(sasl),
    ok = application:start(emysql),
    ok = application:start(game_log).

start(_StartType, _StartArgs) ->
  game_log_sup:start_link().

stop(_State) ->
    ok.

%%start_writer(Count, MQPid) ->


test(Count) ->
  [game_tiny_mq:send_message(game_tiny_mq, {test_log, "test", "test"}) || _ <- lists:seq(1, Count)].
