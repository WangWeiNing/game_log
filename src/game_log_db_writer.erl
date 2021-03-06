%%%-------------------------------------------------------------------
%%% @author WangWeiNing
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 二月 2017 10:05
%%%-------------------------------------------------------------------
-module(game_log_db_writer).
-author("11726").
-behaviour(gen_server).
-include("game_log.hrl").
-include_lib("emysql/include/emysql.hrl").

%% API
-export([
  start_link/1
]).

%% gen_server callback
-export([
  init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  code_change/3,
  terminate/2
]).

%%%====================================
%%% API
%%%====================================

start_link(MQRef) ->
  gen_server:start_link(?MODULE, [MQRef], []).


%%%====================================
%%% GenServer Callback
%%%====================================
init([MQRef]) ->
  {ok, MQRef}.

handle_call(_Msg, _From, State) ->
  {noreply, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info({game_log_message, {_Id, DBRecord} = Msg}, MQRef)
  when is_tuple(Msg)->
  insert_to_db(game_log_database:get_pool_ref(), DBRecord),
  game_log_mq:ack(MQRef),
  {noreply, MQRef};
handle_info({game_log_message, _Msg}, {MQRef, _} = State) ->
  game_log_mq:ack(MQRef),
  {noreply, State};
handle_info(_Msg, State) ->
  {noreply, State}.

code_change(_Old, State, _Extra) ->
  {ok, State}.

terminate(_, _) ->
  ok.

insert_to_db(DBRef, Record) ->
  [Name|Values] = tuple_to_list(Record),
  case fetch_prepare(Name) of
    undefined ->
      prepare_sql(Name, length(Values));
    _ ->
      ok
  end,
  execute_ok(DBRef, Name, Values).


prepare_sql(Name, ValueCount) ->
  Values = string:join(["?" || _ <- lists:seq(1, ValueCount)], ","),
  PrepareSql = list_to_binary("insert into " ++ atom_to_list(Name) ++ "  value (" ++ Values ++ ");"),
  emysql:prepare(Name, PrepareSql),
  Name.

fetch_prepare(Name) ->
  emysql_statements:fetch(Name).


-spec execute_ok(atom()|pid(), atom(), [any()])->ok | {error, any()}.
execute_ok(DBRef, StmtName, Args)->
  Ok = emysql:execute(DBRef, StmtName, Args),
  case Ok of
    #ok_packet{}->ok;
    _->
      error(Ok)
  end.
