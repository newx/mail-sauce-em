%%%-------------------------------------------------------------------
%%% File    : alice_log.erl
%%% Author  : Ari Lerner
%%% Description : 
%%%
%%% Created :  Mon Mar  2 01:00:02 PST 2009
%%%-------------------------------------------------------------------

-module (alice_log).
-behaviour(gen_server).
-include ("alice.hrl").

%% API
-export([start_link/0, stop/0, stop/1, append/1, print/0, 
          error/1,error/2,
          info/1,info/2
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {
            log = []
        }).
-define(SERVER, ?MODULE).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

stop(_Args) -> stop().
stop() -> gen_server:call(?MODULE, stop).

error(Msg) -> error(Msg, []).
error(Msg, Args) -> error_logger:error_msg(lists:flatten(io_lib:format(Msg, Args))).

info(Msg) -> info(Msg, []).
info(Msg, Args) -> error_logger:info_msg(lists:flatten(io_lib:format(Msg, Args))).

append(Log) ->
  gen_server:call(?MODULE, {append, Log}).

print() ->
  gen_server:call(?MODULE, {print}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init([]) ->
  LogPath1 = case application:get_env(alice, log_path) of
    { ok, Log } ->  Log;
    undefined -> "logs/alice.log"
  end,
  Port = case application:get_env(alice, port) of
    { ok, P } ->  P;
    undefined -> 9999
  end,
  Dirname = filename:dirname(LogPath1),
  FilenameWithoutExt = filename:rootname(filename:basename(LogPath1)),
  Extension = filename:extension(LogPath1),
  MyHost = lists:dropwhile(fun (E) -> E =/= $@ end, atom_to_list(node())),
  Realfilename = lists:flatten(lists:append([FilenameWithoutExt, MyHost, ".", erlang:integer_to_list(Port), Extension])),
  
  LogPath = filename:join([Dirname, Realfilename]),
  ?INFO("Logging to path: ~p", [LogPath]),
  
  error_logger:logfile({open, LogPath}),
  error_logger:tty(?TESTING),
  {ok, #state{}}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({append, Log}, _From, State) ->
  {reply, ok, #state{log = [Log | State#state.log]}};
handle_call({print}, _From, State) ->
  handle_print(State#state.log),
  {reply, ok, State};
handle_call(stop, _From, State) ->
  {stop, normal, ok, State};
handle_call(_Request, _From, State) ->
  Reply = ok,
  {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

handle_print([]) -> ok;
handle_print([H|T]) ->
  io:format("~p~n", [H]),
  handle_print(T).