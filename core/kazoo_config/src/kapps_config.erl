%%%-----------------------------------------------------------------------------
%%% @copyright (C) 2011-2018, 2600Hz
%%% @doc
%%% @author Karl Anderson
%%% @author James Aimonetti
%%% @author Pierre Fenoll
%%% @author Roman Galeev
%%% @end
%%%-----------------------------------------------------------------------------
-module(kapps_config).

-include("kazoo_config.hrl").
-include_lib("kazoo_stdlib/include/kazoo_json.hrl").

-export([get/2, get/3, get/4
        ,get_all_kvs/1
        ,get_current/2, get_current/3, get_current/4
        ,get_category/1
        ,fetch_category/1, fetch_category/2
        ]).

-export([get_node_value/2, get_node_value/3, get_node_value/4]).

-export([get_string/2, get_string/3, get_string/4]).
-export([get_binary/2, get_binary/3, get_binary/4]).
-export([get_json/2, get_json/3, get_json/4]).
-export([get_jsons/2, get_jsons/3, get_jsons/4]).
-export([get_atom/2, get_atom/3, get_atom/4]).
-export([get_integer/2, get_integer/3, get_integer/4]).
-export([get_pos_integer/2, get_pos_integer/3, get_pos_integer/4]).
-export([get_non_neg_integer/2, get_non_neg_integer/3, get_non_neg_integer/4]).
-export([get_float/2, get_float/3, get_float/4]).
-export([get_is_false/2, get_is_false/3, get_is_false/4]).
-export([get_is_true/2, get_is_true/3, get_is_true/4]).
-export([get_ne_binary/2, get_ne_binary/3, get_ne_binary/4]).
-export([get_ne_binaries/2, get_ne_binaries/3, get_ne_binaries/4]).
-export([get_ne_binary_or_ne_binaries/2, get_ne_binary_or_ne_binaries/3, get_ne_binary_or_ne_binaries/4]).

-export([set_string/3
        ,set_integer/3
        ,set_float/3
        ,set_boolean/3
        ,set_json/3
        ]).
-export([set/3, set/4, set_default/3, set_node/4
        ,update_default/3, update_default/4
        ]).

-export([lock_db/0, lock_db/1, is_locked/0]).
-export([flush/0, flush/1, flush/2, flush/3]).

-export([migrate/0]).

-ifdef(TEST).
-export([migrate_from_doc/2]).
-endif.

-type config_category() :: kz_term:ne_binary() | nonempty_string() | atom().
-type config_key() :: kz_term:ne_binary() | nonempty_string() | atom() | kz_term:ne_binaries().

-type update_option() :: {'node_specific', boolean()} |
                         {'pvt_fields', kz_term:api_object()}.
-type update_options() :: [update_option()].

-type fetch_ret() :: {'ok', kz_json:object()} |
                     {'error', any()}.

-define(KEY_DEFAULT, <<"default">>).

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a list.
%% @end
%%------------------------------------------------------------------------------

-spec get_string(config_category(), config_key()) -> kz_term:api_string().
get_string(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> kz_term:to_list(Else)
    end.

-spec get_string(config_category(), config_key(), Default) ->
                        nonempty_string() | Default.
get_string(Category, Key, Default) ->
    get_string(Category, Key, Default, kz_term:to_binary(node())).

-spec get_string(config_category(), config_key(), Default, kz_term:ne_binary()) ->
                        nonempty_string() | Default.
get_string(Category, Key, Default, Node) ->
    kz_term:to_list(get(Category, Key, Default, Node)).

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a binary.
%% @end
%%------------------------------------------------------------------------------

-spec get_binary(config_category(), config_key()) -> kz_term:api_binary().
get_binary(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> kz_term:to_binary(Else)
    end.

-spec get_binary(config_category(), config_key(), Default) -> binary() | Default.
get_binary(Category, Key, Default) ->
    get_binary(Category, Key, Default, kz_term:to_binary(node())).

-spec get_binary(config_category(), config_key(), Default, kz_term:ne_binary()) -> binary() | Default.
get_binary(Category, Key, Default, Node) ->
    kz_term:to_binary(get(Category, Key, Default, Node)).

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a JSON.
%% @end
%%------------------------------------------------------------------------------

-spec get_json(config_category(), config_key()) ->
                      kz_term:api_object().
get_json(Category, Key) ->
    V = get(Category, Key),
    as_json_value(V, undefined).

-spec as_json_value(any(), kz_term:api_object()) -> kz_term:api_object().
as_json_value(undefined, Default) -> Default;
as_json_value(V, Default) ->
    case kz_json:is_json_object(V) of
        'true' -> V;
        'false' -> Default
    end.

-spec get_json(config_category(), config_key(), Default) ->
                      kz_json:object() | Default.
get_json(Category, Key, Default) ->
    get_json(Category, Key, Default, kz_term:to_binary(node())).

-spec get_json(config_category(), config_key(), Default, kz_term:ne_binary()) ->
                      kz_json:object() | Default.
get_json(Category, Key, Default, Node) ->
    V = get(Category, Key, Default, Node),
    as_json_value(V, Default).


-spec get_jsons(config_category(), config_key()) ->
                       kz_json:objects().
get_jsons(Category, Key) ->
    V = get(Category, Key),
    as_jsons_value(V, []).

-spec as_jsons_value(any(), kz_json:objects()) -> kz_json:objects().
as_jsons_value(undefined, Default) -> Default;
as_jsons_value(V, Default) ->
    case lists:all(fun kz_json:is_json_object/1, V) of
        true -> V;
        false -> Default
    end.

-spec get_jsons(config_category(), config_key(), Default) ->
                       kz_json:objects() | Default.
get_jsons(Category, Key, Default) ->
    get_jsons(Category, Key, Default, kz_term:to_binary(node())).

-spec get_jsons(config_category(), config_key(), Default, kz_term:ne_binary()) ->
                       kz_json:objects() | Default.
get_jsons(Category, Key, Default, Node) ->
    V = get(Category, Key, Default, Node),
    as_jsons_value(V, Default).

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a atom.
%% @end
%%------------------------------------------------------------------------------

-spec get_atom(config_category(), config_key()) -> kz_term:api_atom().
get_atom(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> kz_term:to_atom(Else, 'true')
    end.

-spec get_atom(config_category(), config_key(), Default) -> atom() | Default.
get_atom(Category, Key, Default) ->
    get_atom(Category, Key, Default, kz_term:to_binary(node())).

-spec get_atom(config_category(), config_key(), Default, kz_term:ne_binary()) -> atom() | Default.
get_atom(Category, Key, Default, Node) ->
    kz_term:to_atom(get(Category, Key, Default, Node), 'true').

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a integer.
%% @end
%%------------------------------------------------------------------------------

-spec get_integer(config_category(), config_key()) -> kz_term:api_integer().
get_integer(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> kz_term:to_integer(Else)
    end.

-spec get_integer(config_category(), config_key(), Default) -> integer() | Default.
get_integer(Category, Key, Default) ->
    get_integer(Category, Key, Default, kz_term:to_binary(node())).

-spec get_integer(config_category(), config_key(), Default, kz_term:ne_binary()) -> integer() | Default.
get_integer(Category, Key, Default, Node) ->
    case get(Category, Key, Default, Node) of
        'undefined' -> 'undefined';
        Else -> kz_term:to_integer(Else)
    end.

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a `pos_integer'.
%% @end
%%------------------------------------------------------------------------------

-spec get_pos_integer(config_category(), config_key()) -> kz_term:api_pos_integer().
get_pos_integer(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> to_pos_integer(Else, undefined)
    end.

-spec get_pos_integer(config_category(), config_key(), Default) -> pos_integer() | Default.
get_pos_integer(Category, Key, Default) ->
    get_pos_integer(Category, Key, Default, kz_term:to_binary(node())).

-spec get_pos_integer(config_category(), config_key(), Default, kz_term:ne_binary()) -> pos_integer() | Default.
get_pos_integer(Category, Key, Default, Node) ->
    to_pos_integer(get(Category, Key, Default, Node), Default).

to_pos_integer(Value, Default) ->
    case kz_term:to_integer(Value) of
        PosInteger when is_integer(Value), Value > 0 ->
            PosInteger;
        _ -> Default
    end.

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a `pos_integer'.
%% @end
%%------------------------------------------------------------------------------

-spec get_non_neg_integer(config_category(), config_key()) -> kz_term:api_non_neg_integer().
get_non_neg_integer(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> to_non_neg_integer(Else, undefined)
    end.

-spec get_non_neg_integer(config_category(), config_key(), Default) -> non_neg_integer() | Default.
get_non_neg_integer(Category, Key, Default) ->
    get_non_neg_integer(Category, Key, Default, kz_term:to_binary(node())).

-spec get_non_neg_integer(config_category(), config_key(), Default, kz_term:ne_binary()) -> non_neg_integer() | Default.
get_non_neg_integer(Category, Key, Default, Node) ->
    to_non_neg_integer(get(Category, Key, Default, Node), Default).

to_non_neg_integer(Value, Default) ->
    case kz_term:to_integer(Value) of
        NonNegInteger when is_integer(Value), Value >= 0 ->
            NonNegInteger;
        _ -> Default
    end.

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a `float'.
%% @end
%%------------------------------------------------------------------------------

-spec get_float(config_category(), config_key()) -> kz_term:api_float().
get_float(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> kz_term:to_float(Else)
    end.

-spec get_float(config_category(), config_key(), Default) -> float() | Default.
get_float(Category, Key, Default) ->
    get_float(Category, Key, Default, kz_term:to_binary(node())).

-spec get_float(config_category(), config_key(), Default, kz_term:ne_binary()) -> float() | Default.
get_float(Category, Key, Default, Node) ->
    kz_term:to_float(get(Category, Key, Default, Node)).

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a `is_false'.
%% @end
%%------------------------------------------------------------------------------

-spec get_is_false(config_category(), config_key()) -> kz_term:api_boolean().
get_is_false(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> kz_term:is_false(Else)
    end.

-spec get_is_false(config_category(), config_key(), Default) -> boolean() | Default.
get_is_false(Category, Key, Default) ->
    get_is_false(Category, Key, Default, kz_term:to_binary(node())).

-spec get_is_false(config_category(), config_key(), Default, kz_term:ne_binary()) -> boolean() | Default.
get_is_false(Category, Key, Default, Node) ->
    kz_term:is_false(get(Category, Key, Default, Node)).

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category and cast it as a `is_true'.
%% @end
%%------------------------------------------------------------------------------

-spec get_is_true(config_category(), config_key()) -> kz_term:api_boolean().
get_is_true(Category, Key) ->
    case get(Category, Key) of
        'undefined' -> 'undefined';
        Else -> kz_term:is_true(Else)
    end.

-spec get_is_true(config_category(), config_key(), Default) -> boolean() | Default.
get_is_true(Category, Key, Default) ->
    get_is_true(Category, Key, Default, kz_term:to_binary(node())).

-spec get_is_true(config_category(), config_key(), Default, kz_term:ne_binary()) -> boolean() | Default.
get_is_true(Category, Key, Default, Node) ->
    kz_term:is_true(get(Category, Key, Default, Node)).


-spec get_ne_binary_or_ne_binaries(config_category(), config_key()) -> kz_term:api_ne_binary() | kz_term:ne_binaries().
get_ne_binary_or_ne_binaries(Category, Key) ->
    get_ne_binary_or_ne_binaries(Category, Key, 'undefined').

-spec get_ne_binary_or_ne_binaries(config_category(), config_key(), Default) -> kz_term:ne_binary() | kz_term:ne_binaries() | Default.
get_ne_binary_or_ne_binaries(Category, Key, Default) ->
    get_ne_binary_or_ne_binaries(Category, Key, Default, kz_term:to_binary(node())).

-spec get_ne_binary_or_ne_binaries(config_category(), config_key(), Default, kz_term:ne_binary()) -> kz_term:ne_binary() | kz_term:ne_binaries() | Default.
get_ne_binary_or_ne_binaries(Category, Key, Default, Node) ->
    ValueOrValues = get(Category, Key, Default, Node),
    case kz_term:is_empty(ValueOrValues) of
        'true' -> Default;
        'false' ->
            case ValueOrValues of
                Value=?NE_BINARY -> Value;
                Values when is_list(Values) ->
                    [kz_term:to_binary(Value)
                     || Value <- Values,
                        kz_term:is_not_empty(Value)
                    ]
            end
    end.


-spec get_ne_binary(config_category(), config_key()) -> kz_term:api_ne_binary().
get_ne_binary(Category, Key) ->
    get_ne_binary(Category, Key, 'undefined').

-spec get_ne_binary(config_category(), config_key(), Default) -> kz_term:ne_binary() | Default.
get_ne_binary(Category, Key, Default) ->
    get_ne_binary(Category, Key, Default, kz_term:to_binary(node())).

-spec get_ne_binary(config_category(), config_key(), Default, kz_term:ne_binary()) -> kz_term:ne_binary() | Default.
get_ne_binary(Category, Key, Default, Node) ->
    Value = get(Category, Key, Default, Node),
    case kz_term:is_empty(Value) of
        'true' -> Default;
        'false' -> kz_term:to_binary(Value)
    end.


-spec get_ne_binaries(config_category(), config_key()) -> kz_term:api_ne_binaries().
get_ne_binaries(Category, Key) ->
    get_ne_binaries(Category, Key, 'undefined').

-spec get_ne_binaries(config_category(), config_key(), Default) -> kz_term:ne_binaries() | Default.
get_ne_binaries(Category, Key, Default) ->
    get_ne_binaries(Category, Key, Default, kz_term:to_binary(node())).

-spec get_ne_binaries(config_category(), config_key(), Default, kz_term:ne_binary()) -> kz_term:ne_binaries() | Default.
get_ne_binaries(Category, Key, Default, Node) ->
    Values = get(Category, Key, Default, Node),
    case kz_term:is_empty(Values) of
        'true' -> Default;
        'false' ->
            [kz_term:to_binary(Value)
             || Value <- Values,
                kz_term:is_not_empty(Value)
            ]
    end.


%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category but only if its configured
%%  explicitly for the node.
%% @end
%%------------------------------------------------------------------------------

-spec get_node_value(config_category(), config_key()) -> any() | 'undefined'.
get_node_value(Category, Key) ->
    get_node_value(Category, Key, 'undefined').

-spec get_node_value(config_category(), config_key(), Default) -> any() | Default.
get_node_value(Category, Key, Default) ->
    get_node_value(Category, Key, Default, node()).

-spec get_node_value(config_category(), config_key(), Default, kz_term:ne_binary() | atom()) -> any() | Default.
get_node_value(Category, Key, Default, Node) when not is_list(Key) ->
    get_node_value(Category, [kz_term:to_binary(Key)], Default, Node);
get_node_value(Category, Keys, Default, Node) when not is_binary(Category) ->
    get_node_value(kz_term:to_binary(Category), Keys, Default, Node);
get_node_value(Category, Keys, Default, Node) when not is_binary(Node) ->
    get_node_value(Category, Keys, Default, kz_term:to_binary(Node));
get_node_value(Category, Keys, Default, Node) ->
    case get_category(Category) of
        {'ok', JObj} ->
            Node = kz_term:to_binary(node()),
            kz_json:get_value([Node | Keys], JObj);
        {'error', 'not_found'} ->
            lager:debug("missing category ~s ~p: ~p", [Category, Keys, Default]),
            Default
    end.

%%------------------------------------------------------------------------------
%% @doc Get a configuration key for a given category.
%% Also, when looking up the key see if there is a value specific to this
%% node but if there is not then use the default value.
%% @end
%%------------------------------------------------------------------------------

-spec get(config_category(), config_key()) -> any() | 'undefined'.
get(Category, Key) ->
    get(Category, Key, 'undefined').

-spec get(config_category(), config_key(), Default) -> any() | Default.
get(Category, Key, Default) ->
    get(Category, Key, Default, node()).

-spec get(config_category(), config_key(), Default, kz_term:ne_binary() | atom()) -> any() | Default.
get(Category, Key, Default, 'undefined') ->
    get(Category, Key, Default, ?KEY_DEFAULT);
get(Category, Key, Default, Node) when not is_list(Key) ->
    get(Category, [kz_term:to_binary(Key)], Default, Node);
get(Category, Keys, Default, Node) when not is_binary(Category) ->
    get(kz_term:to_binary(Category), Keys, Default, Node);
get(Category, Keys, Default, Node) when not is_binary(Node) ->
    get(Category, Keys, Default, kz_term:to_binary(Node));
get(Category, Keys, Default, Node) ->
    case get_category(Category) of
        {'ok', JObj} -> get_value(Category, Node, Keys, Default, JObj);
        {'error', 'not_found'} ->
            lager:debug("missing category ~s(default) ~p: ~p", [Category, Keys, Default]),
            _ = set(Category, Keys, Default),
            Default;
        {'error', Error} ->
            lager:debug("error ~p getting  category ~s(default) ~p: ~p", [Error, Category, Keys, Default]),
            Default
    end.


-spec get_current(config_category(), config_key()) -> any() | 'undefined'.
get_current(Category, Key) ->
    get_current(Category, Key, 'undefined').

-spec get_current(config_category(), config_key(), Default) -> any() | Default.
get_current(Category, Key, Default) ->
    get_current(Category, Key, Default, node()).

-spec get_current(config_category(), config_key(), Default, kz_term:ne_binary() | atom()) -> any() | Default.
get_current(Category, Key, Default, 'undefined') ->
    get_current(Category, Key, Default, ?KEY_DEFAULT);
get_current(Category, Key, Default, Node) when not is_list(Key) ->
    get_current(Category, [kz_term:to_binary(Key)], Default, Node);
get_current(Category, Keys, Default, Node) when not is_binary(Category) ->
    get_current(kz_term:to_binary(Category), Keys, Default, Node);
get_current(Category, Keys, Default, Node) when not is_binary(Node) ->
    get_current(Category, Keys, Default, kz_term:to_binary(Node));
get_current(Category, Keys, Default, Node) ->
    case get_category(Category, 'false') of
        {'ok', JObj} -> get_value(Category, Node, Keys, Default, JObj);
        {'error', 'not_found'} ->
            lager:debug("missing category ~s(default) ~p: ~p", [Category, Keys, Default]),
            _ = set(Category, Keys, Default),
            Default;
        {'error', Error} ->
            lager:debug("error ~p getting  category ~s(default) ~p: ~p", [Error, Category, Keys, Default]),
            Default
    end.

-spec get_value(config_category(), config_key(), config_key(), Default, kz_json:object()) ->
                       Default | any().
get_value(Category, ?KEY_DEFAULT, Keys, Default, JObj) ->
    get_default_value(Category, Keys, Default, JObj);
get_value(Category, Node, Keys, Default, JObj) ->
    case kz_json:get_value([Node | Keys], JObj) of
        'undefined' -> get_zone_value(Category, Node, Keys, Default, JObj);
        Else -> Else
    end.

-spec get_zone_value(config_category(), config_key(), config_key(), Default, kz_json:object()) ->
                            Default | any().
get_zone_value(Category, _Node, Keys, Default, JObj) ->
    Zone = kz_term:to_binary(kz_config:zone()),
    case kz_json:get_value([Zone | Keys], JObj) of
        'undefined' -> get_default_value(Category, Keys, Default, JObj);
        Else -> Else
    end.

-spec get_default_value(config_category(), config_key(), Default, kz_json:object()) ->
                               Default | _.
get_default_value(_Category, [?KEY_DEFAULT | Keys], Default, JObj) ->
    case kz_json:get_value([?KEY_DEFAULT | Keys], JObj) of
        'undefined' -> Default;
        Else -> Else
    end;
get_default_value(_Category, Keys, Default, JObj) ->
    case kz_json:get_value([?KEY_DEFAULT | Keys], JObj) of
        'undefined' when Default =/= 'undefined' -> Default;
        Else -> Else
    end.

%%------------------------------------------------------------------------------
%% @doc Get all Key-Value pairs for a given category.
%% @end
%%------------------------------------------------------------------------------
-spec get_all_kvs(kz_term:ne_binary()) -> kz_term:proplist().
get_all_kvs(Category) ->
    case get_category(Category) of
        {'error', _} -> [];
        {'ok', JObj} -> get_all_kvs(kz_term:to_binary(node()), JObj)
    end.

-spec get_all_kvs(kz_term:ne_binary(), kz_json:object()) -> kz_term:proplist().
get_all_kvs(Node, JObj) ->
    case kz_json:get_value(Node, JObj) of
        'undefined' -> get_all_default_kvs(JObj);
        NodeJObj -> kz_json:to_proplist(NodeJObj)
    end.

-spec get_all_default_kvs(kz_json:object()) -> kz_term:proplist().
get_all_default_kvs(JObj) ->
    case kz_json:get_value(?KEY_DEFAULT, JObj) of
        'undefined' -> [];
        DefJObj -> kz_json:to_proplist(DefJObj)
    end.

%%------------------------------------------------------------------------------
%% @doc
%% @end
%%------------------------------------------------------------------------------

-spec set_string(config_category(), config_key(), kz_term:text() | binary() | string()) ->
                        {'ok', kz_json:object()}.
set_string(Category, Key, Value) ->
    set(Category, Key, kz_term:to_binary(Value)).

-spec set_integer(config_category(), config_key(), kz_term:text() | integer()) ->
                         {'ok', kz_json:object()}.
set_integer(Category, Key, Value) ->
    set(Category, Key, kz_term:to_integer(Value)).

-spec set_float(config_category(), config_key(), kz_term:text() | float()) ->
                       {'ok', kz_json:object()}.
set_float(Category, Key, Value) ->
    set(Category, Key, kz_term:to_float(Value)).

-spec set_boolean(config_category(), config_key(), kz_term:text() | boolean()) ->
                         {'ok', kz_json:object()}.
set_boolean(Category, Key, Value) ->
    set(Category, Key, kz_term:to_boolean(Value)).

-spec set_json(config_category(), config_key(), kz_term:text() | kz_json:object()) ->
                      {'ok', kz_json:object()}.
set_json(Category, Key, Value) ->
    set(Category, Key, kz_json:decode(Value)).

%%------------------------------------------------------------------------------
%% @doc Set the key to the value in the given category but specific to this node.
%% @end
%%------------------------------------------------------------------------------
-spec set(config_category(), config_key(), any()) ->
                 {'ok', kz_json:object()}.
set(Category, Key, Value) ->
    set(Category, Key, Value, node()).

-spec set(config_category(), config_key(), any(), kz_term:ne_binary() | atom()) ->
                 {'ok', kz_json:object()}.
set(Category, Key, Value, Node) ->
    update_category(Category, Key, Value, Node, []).

-spec set_default(config_category(), config_key(), any()) ->
                         {'ok', kz_json:object()} | 'ok' |
                         {'error', any()}.
set_default(Category, Key, Value) ->
    update_category(Category, Key, Value, ?KEY_DEFAULT, []).

-spec update_default(config_category(), config_key(), kz_json:json_term()) ->
                            {'ok', kz_json:object()} | 'ok' |
                            {'error', any()}.
update_default(Category, Key, Value) ->
    update_default(Category, Key, Value, []).

-spec update_default(config_category(), config_key(), kz_json:json_term(), update_options()) ->
                            {'ok', kz_json:object()} | 'ok' |
                            {'error', any()}.
update_default(Category, Key, Value, Options) ->
    update_category(Category, Key, Value, ?KEY_DEFAULT, Options).

-spec set_node(config_category(), config_key(), any(), kz_term:ne_binary() | atom()) ->
                      'ok' |
                      {'ok', kz_json:object()}.
set_node(Category, _, _, 'undefined') -> get_category(Category);
set_node(Category, Key, Value, Node) ->
    update_category(Category, Key, Value, Node, [{'node_specific', 'true'}]).

-spec update_category(config_category(), config_key(), any(), kz_term:ne_binary() | atom(), update_options()) ->
                             'ok' |
                             {'ok', kz_json:object()} |
                             {'error', any()}.
-ifdef(TEST).
update_category(_, _, _, _, _) -> 'ok'.
-else.
update_category('undefined', _, _, _, _) -> 'ok';
update_category(_, 'undefined', _, _, _) -> 'ok';
update_category(_, _, 'undefined', _, _) -> 'ok';
update_category(Category, Key, Value, 'undefined', Options) ->
    update_category(Category, Key, Value, ?KEY_DEFAULT, Options);
update_category(Category, Key, Value, Node, Options) when not is_list(Key) ->
    update_category(Category, [kz_term:to_binary(Key)], Value, Node, Options);
update_category(Category, Key, Value, Node, Options) when not is_binary(Category) ->
    update_category(kz_term:to_binary(Category), Key, Value, Node, Options);
update_category(Category, Key, Value, Node, Options) when not is_binary(Node) ->
    update_category(Category, Key, Value, kz_term:to_binary(Node), Options);
update_category(Category, Keys, Value, Node, Options) ->
    lager:debug("setting ~s(~p): ~p", [Category, Keys, Value]),
    case kz_datamgr:open_cache_doc(?KZ_CONFIG_DB, Category) of
        {'ok', JObj} ->
            lager:debug("updating category ~s(~s).~s to ~p", [Category
                                                             ,Node
                                                             ,kz_binary:join(Keys)
                                                             ,Value
                                                             ]),
            update_category(Category, Keys, Value, Node, Options, JObj);
        {'error', 'not_found'} ->
            lager:debug("config ~s not found, using empty for now", [Category]),
            update_category(Category, Keys, Value, Node, Options, kz_json:new());
        {'error', _Reason}=E ->
            lager:debug("failed to update category ~s: ~p", [Category, kz_datamgr:format_error(_Reason)]),
            E
    end.

-spec update_category(config_category(), config_key(), any(), kz_term:ne_binary(), update_options(), kz_json:object())
                     -> {'ok', kz_json:object()}.
update_category(Category, Keys, Value, Node, Options, JObj) ->
    PvtFields = props:get_value('pvt_fields', Options),
    L = [Node | Keys],
    case kz_json:get_value(L, JObj) =/= 'undefined'
        orelse props:is_true('node_specific', Options, 'false')
    of
        'true' ->
            update_category(Category, kz_json:set_value(L, Value, JObj), PvtFields);
        'false' ->
            update_category(Category, kz_json:set_value([?KEY_DEFAULT | Keys], Value, JObj), PvtFields)
    end.

-spec update_category(config_category(), kz_json:object(), kz_term:api_object()) ->
                             {'ok', kz_json:object()}.
update_category(Category, JObj, PvtFields) ->
    case maybe_save_category(Category, JObj, PvtFields) of
        {'ok', _}=OK -> OK;
        {'error', 'conflict'} ->
            lager:debug("conflict saving ~s, merging and saving", [Category]),
            {'ok', Updated} = kz_datamgr:open_doc(?KZ_CONFIG_DB, Category),
            Merged = kz_json:merge_jobjs(Updated, kz_doc:public_fields(JObj, 'false')),
            lager:debug("updating from ~s to ~s", [kz_doc:revision(JObj), kz_doc:revision(Merged)]),
            NewPvtFields = case PvtFields of
                               'undefined' -> PvtFields;
                               PvtFields -> kz_json:delete_key(<<"_rev">>, PvtFields)
                           end,
            update_category(Category, Merged, NewPvtFields)
    end.
-endif.


-spec maybe_save_category(kz_term:ne_binary(), kz_json:object(), kz_term:api_object()) ->
                                 {'ok', kz_json:object()} |
                                 {'error', 'conflict'}.
maybe_save_category(Category, JObj, PvtFields) ->
    maybe_save_category(Category, JObj, PvtFields, 'false').

-spec maybe_save_category(kz_term:ne_binary(), kz_json:object(), kz_term:api_object(), boolean()) ->
                                 {'ok', kz_json:object()} |
                                 {'error', 'conflict'}.
maybe_save_category(Category, JObj, PvtFields, Looped) ->
    maybe_save_category(Category, JObj, PvtFields, Looped, is_locked()).

-spec maybe_save_category(kz_term:ne_binary(), kz_json:object(), kz_term:api_object(), boolean(), boolean()) ->
                                 {'ok', kz_json:object()} |
                                 {'error', 'conflict'}.
maybe_save_category(_, JObj, _, _, 'true') ->
    lager:warning("failed to update category, system config database is locked!"),
    lager:warning("please update /etc/kazoo/config.ini or use 'sup kapps_config lock_db <boolean>' to enable system config writes."),
    {'ok', JObj};
maybe_save_category(Category, JObj, PvtFields, Looped, _) ->
    lager:debug("updating configuration category ~s(~s)"
               ,[Category, kz_doc:revision(JObj)]
               ),

    JObj1 = update_pvt_fields(Category, JObj, PvtFields),

    case kz_datamgr:save_doc(?KZ_CONFIG_DB, JObj1) of
        {'ok', SavedJObj}=Ok ->
            lager:debug("saved cat ~s to db ~s (~s)", [Category, ?KZ_CONFIG_DB, kz_doc:revision(SavedJObj)]),
            _ = kz_datamgr:add_to_doc_cache(?KZ_CONFIG_DB, Category, SavedJObj),
            Ok;
        {'error', 'not_found'} when not Looped ->
            lager:debug("attempting to create ~s DB", [?KZ_CONFIG_DB]),
            'true' = kz_datamgr:db_create(?KZ_CONFIG_DB),
            maybe_save_category(Category, JObj, PvtFields, 'true');
        {'error', 'conflict'}=E -> E;
        {'error', _R} ->
            lager:warning("unable to update ~s system config doc: ~p", [Category, _R]),
            _ = kz_datamgr:add_to_doc_cache(?KZ_CONFIG_DB, Category, JObj1),
            {'ok', JObj1}
    end.

-spec update_pvt_fields(config_category(), kz_json:object(), kz_term:api_object()) ->
                               kz_json:object().
update_pvt_fields(Category, JObj, 'undefined') ->
    kz_doc:update_pvt_parameters(kz_doc:set_id(JObj, Category)
                                ,?KZ_CONFIG_DB
                                ,[{'type', <<"config">>}]
                                );
update_pvt_fields(Category, JObj, PvtFields) ->
    Base = update_pvt_fields(Category, JObj, 'undefined'),
    kz_json:merge_jobjs(Base, PvtFields).

%%------------------------------------------------------------------------------
%% @doc Lock configuration document.
%% @end
%%------------------------------------------------------------------------------

-spec lock_db() -> 'ok'.
lock_db() ->
    lock_db('true').

-spec lock_db(kz_term:text() | boolean()) -> 'ok'.
lock_db('true') ->
    kz_config:set('kazoo_apps', 'lock_system_config', 'true');
lock_db('false') ->
    kz_config:unset('kazoo_apps', 'lock_system_config');
lock_db(Value) when is_binary(Value) ->
    lock_db(kz_term:to_atom(Value));
lock_db(Value) ->
    lager:warning("wrong parameter ~p. use either 'true' or 'false'", [Value]).

%%------------------------------------------------------------------------------
%% @doc Check if configuration document locked or not.
%% @end
%%------------------------------------------------------------------------------
-spec is_locked() -> boolean().
is_locked() ->
    case kz_config:get_atom('kazoo_apps', 'lock_system_config') of
        [] -> 'false';
        [Value] -> Value
    end.

%%------------------------------------------------------------------------------
%% @doc Flush the configuration cache.
%% @end
%%------------------------------------------------------------------------------
-spec flush() -> 'ok'.
flush() ->
    _ = kz_cache:flush_local(?KAPPS_CONFIG_CACHE),
    kz_datamgr:flush_cache_docs(?KZ_CONFIG_DB).

-spec flush(kz_term:ne_binary()) -> 'ok'.
flush(Category) ->
    _ = kz_cache:flush_local(?KAPPS_CONFIG_CACHE),
    kz_datamgr:flush_cache_doc(?KZ_CONFIG_DB, Category).

-spec flush(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
flush(Category, Key) ->
    flush(Category, Key, ?KEY_DEFAULT).

-spec flush(kz_term:ne_binary(), kz_term:ne_binary() | kz_term:ne_binaries(), kz_term:api_ne_binary()) -> 'ok'.
flush(Category, Key, 'undefined') ->
    flush(Category, Key);
flush(Category, Key, <<"undefined">>) ->
    flush(Category, Key);

flush(Category, Key, Node) when not is_list(Key) ->
    flush(Category, [Key], Node);
flush(Category, Keys, Node) when not is_binary(Category) ->
    flush(kz_term:to_binary(Category), Keys, Node);
flush(Category, Keys, Node) when not is_binary(Node) ->
    flush(Category, Keys, kz_term:to_binary(Node));
flush(Category, Keys, Node) ->
    case get_category(Category) of
        {'error', _} -> 'ok';
        {'ok', JObj} ->
            J = kz_json:delete_key([Node | Keys], JObj),
            _ = kz_datamgr:add_to_doc_cache(?KZ_CONFIG_DB, Category, J),
            'ok'
    end.

%%------------------------------------------------------------------------------
%% @doc Fetch a given configuration category from (in order).
%% 1. from the cache
%% 2. from the db
%% 3. from a flat file
%% @end
%%------------------------------------------------------------------------------

-spec get_category(kz_term:ne_binary()) -> fetch_ret().
get_category(Category) ->
    get_category(Category, 'true').

-ifdef(TEST).

-spec get_category(kz_term:ne_binary(), boolean()) -> fetch_ret().
get_category(Category, _)
  when Category =:= <<"test_account_config">>;
       Category =:= <<"test_account_config_sub_empty">>;
       Category =:= <<"test_account_config_reseller_only">>;
       Category =:= <<"test_account_config_reseller_system">>;
       Category =:= <<"test_account_config_system_empty">>;
       Category =:= <<"test_account_config_system_only">>;
       Category =:= <<"no_cat_please">> ->
    kz_datamgr:open_doc(?KZ_CONFIG_DB, Category);
get_category(_, _) ->
    {'error', 'not_found'}.
-else.

-spec get_category(kz_term:ne_binary(), boolean()) -> fetch_ret().
get_category(Category, 'true') ->
    case kz_datamgr:open_cache_doc(?KZ_CONFIG_DB, Category, [{'cache_failures', ['not_found']}]) of
        {'ok', JObj} -> {'ok', kapps_config_doc:config_with_default_node(JObj)};
        _Other -> {'ok', kapps_config_doc:build_default(Category)}
    end;
get_category(Category, 'false') ->
    case kz_datamgr:open_doc(?KZ_CONFIG_DB, Category) of
        {'ok', JObj} -> {'ok', kapps_config_doc:config_with_default_node(JObj)};
        _Other -> _Other
    end.
-endif.


-spec fetch_category(kz_term:ne_binary()) -> fetch_ret().
fetch_category(Category) ->
    fetch_category(Category, 'true').

-ifdef(TEST).

-spec fetch_category(kz_term:ne_binary(), boolean()) -> fetch_ret().
fetch_category(Category, _)
  when Category =:= <<"test_account_config">>;
       Category =:= <<"test_account_config_sub_empty">>;
       Category =:= <<"test_account_config_reseller_only">>;
       Category =:= <<"test_account_config_reseller_system">>;
       Category =:= <<"test_account_config_system_empty">>;
       Category =:= <<"test_account_config_system_only">>;
       Category =:= <<"no_cat_please">> ->
    kz_datamgr:open_doc(?KZ_CONFIG_DB, Category);
fetch_category(_, _) ->
    {'error', 'not_found'}.
-else.

-spec fetch_category(kz_term:ne_binary(), boolean()) -> fetch_ret().
fetch_category(Category, 'true') ->
    kz_datamgr:open_cache_doc(?KZ_CONFIG_DB, Category, [{'cache_failures', ['not_found']}]);
fetch_category(Category, 'false') ->
    kz_datamgr:open_doc(?KZ_CONFIG_DB, Category).
-endif.

%%------------------------------------------------------------------------------
%% @doc This function will move a system config setting from one location
%% to another.  It will create the document if it does not already
%% exist and will move per-node settings if they exist.
%% In the event that both the source and destination exist but
%% have different values it will not make any change.  The parameter
%% is only removed from the source after a successful save of the
%% the destination.
%% @end
%%------------------------------------------------------------------------------
-type migrate_setting() :: {kz_term:ne_binary(), config_key()} | kz_term:ne_binary().
-type migrate_value() :: {kz_term:ne_binary(), kz_term:ne_binary(), config_key(), _}.
-type migrate_values() :: [migrate_value()].

-define(CONFIG_MIGRATIONS
       ,[{{<<"reorder">>, <<"unknown-error-code">>}
         ,{<<"reorder">>, [<<"unknown_number">>, <<"response_code">>]}
         }
        ,{{<<"reorder">>, <<"unknown-error-message">>}
         ,{<<"reorder">>, [<<"unknown_number">>, <<"response_message">>]}
         }
        ,{{<<"reorder">>, <<"known-error-code">>}
         ,{<<"reorder">>, [<<"known_number">>, <<"response_code">>]}
         }
        ,{{<<"reorder">>, <<"known-error-message">>}
         ,{<<"reorder">>, [<<"known_number">>, <<"response_message">>]}
         }

        ,{{<<"callflow">>, <<"default_emergency_cid_number">>}
         ,{<<"stepswitch">>, <<"default_emergency_cid_number">>}
         }
        ,{{<<"callflow">>, <<"ensure_valid_emergency_number">>}
         ,{<<"stepswitch">>, <<"ensure_valid_emergency_cid">>}
         }
        ,{{<<"callflow">>, <<"default_caller_id_number">>}
         ,{<<"kazoo_endpoint">>, <<"default_caller_id_number">>}
         }
        ,{{<<"callflow">>, <<"default_caller_id_name">>}
         ,{<<"kazoo_endpoint">>, <<"default_caller_id_name">>}
         }
        ,{{<<"callflow">>, <<"default_can_text_self">>}
         ,{<<"kazoo_endpoint">>, <<"default_can_text_self">>}
         }
        ,{{<<"callflow">>, <<"restrict_to_known_types">>}
         ,{<<"kazoo_endpoint">>, <<"restrict_to_known_types">>}
         }
        ,{{<<"callflow">>, <<"sip_transport">>}
         ,{<<"kazoo_endpoint">>, <<"sip_transport">>}
         }
        ,{{<<"callflow">>, <<"custom_sip_interface">>}
         ,{<<"kazoo_endpoint">>, <<"custom_sip_interface">>}
         }
        ,{{<<"callflow">>, <<"should_add_diversion_header">>}
         ,{<<"kazoo_endpoint">>, <<"should_add_diversion_header">>}
         }
        ,{{<<"callflow">>, <<"default_ignore_completed_elsewhere">>}
         ,{<<"kazoo_endpoint">>, <<"default_ignore_completed_elsewhere">>}
         }
        ,{{<<"callflow.mobile">>, <<"create_sip_endpoint">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"create_sip_endpoint">>}
         }
        ,{{<<"callflow.mobile">>, <<"codecs">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"codecs">>}
         }
        ,{{<<"callflow.mobile">>, <<"custom_sip_interface">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"custom_sip_interface">>}
         }
        ,{{<<"callflow.mobile">>, <<"formatter">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"formatter">>}
         }
        ,{{<<"callflow.mobile">>, <<"prefix">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"prefix">>}
         }
        ,{{<<"callflow.mobile">>, <<"suffix">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"suffix">>}
         }
        ,{{<<"callflow.mobile">>, <<"realm">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"realm">>}
         }
        ,{{<<"callflow.mobile">>, <<"path">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"path">>}
         }
        ,{{<<"callflow.mobile">>, <<"sms_interface">>}
         ,{<<"kazoo_endpoint.mobile">>, <<"sms_interface">>}
         }
        ,{{<<"callflow">>, <<"recorder_module">>}
         ,{<<"kazoo_endpoint">>, <<"recorder_module">>}
         }

        ,{{<<"trunkstore">>, <<"ensure_valid_emergency_number">>}
         ,{<<"stepswitch">>, <<"ensure_valid_emergency_cid">>}
         }

        ,{{<<"number_manager">>, <<"aging_expiry_d">>}
         ,{<<"tasks">>, <<"aging_expiry_d">>}
         }
        ,{{<<"number_manager">>, <<"discovery_expiry_d">>}
         ,{<<"tasks">>, <<"discovery_expiry_d">>}
         }
        ,{{<<"number_manager">>, <<"aging_expiry_d">>}
         ,{<<"tasks">>, <<"aging_expiry_d">>}
         }
        ,{{<<"number_manager">>, <<"crawler_timer_ms">>}
         ,{<<"tasks">>, <<"crawler_timer_ms">>}
         }
        ,{{<<"number_manager.port_request">>, <<"crawler_delay_time_ms">>}
         ,{<<"tasks">>, <<"crawler_delay_time_ms">>}
         }
        ,{{<<"number_manager">>, <<"porting_module_name">>}
         ,{<<"number_manager">>, <<"port_in_module_name">>}
         }

        ,{{<<"notify.account_crawler">>, <<"interaccount_delay">>}
         ,{<<"tasks">>, <<"interaccount_delay_ms">>}
         }
        ,{{<<"notify.account_crawler">>, <<"cycle_delay_time">>}
         ,{<<"tasks">>, <<"cycle_delay_time_ms">>}
         }
        ,{{<<"notify.account_crawler">>, <<"crawl_for_first_occurrence">>}
         ,{<<"tasks">>, <<"should_crawl_for_first_occurrence">>}
         }
        ,{{<<"notify.account_crawler">>, <<"crawl_for_low_balance">>}
         ,{<<"tasks">>, <<"should_crawl_for_low_balance">>}
         }
        ,{{<<"notify.account_crawler">>, <<"low_balance_repeat_s">>}
         ,{<<"tasks">>, <<"low_balance_repeat_s">>}
         }

        ,{{<<"crossbar">>, <<"cleanup_timer">>}
         ,{<<"tasks">>, <<"browse_dbs_interval_s">>}
         }
        ,{{<<"crossbar">>, <<"soft_delete_pause_ms">>}
         ,{<<"tasks">>, <<"soft_delete_pause_ms">>}
         }
        ,{{<<"crossbar">>, <<"token_auth_expiry">>}
         ,{<<"crossbar.auth">>, <<"token_auth_expiry_s">>}
         }
        ,{{<<"cb_modb">>, <<"maybe_archive_modbs">>}
         ,{<<"tasks">>, <<"should_archive_modbs">>}
         }
        ,{{<<"cb_port_requests">>, <<"unfinished_port_request_lifetime_s">>}
         ,{<<"tasks">>, <<"unfinished_port_request_lifetime_s">>}
         }

        ,{{<<"callflow">>, <<"privacy_name">>}
         ,{<<"privacy">>, <<"privacy_name">>}
         }
        ,{{<<"callflow">>, <<"privacy_number">>}
         ,{<<"privacy">>, <<"privacy_number">>}
         }
        ,{{<<"stepswitch">>, <<"block_anonymous_caller_id">>}
         ,{<<"privacy">>, <<"block_anonymous_caller_id">>}
         }

        ,{{<<"fax">>, <<"conversion_command">>}
         ,{<<"fax">>, <<"conversion_pdf_command">>}
         }

        ,{{<<"media">>, <<"tts_cache">>}
         ,{<<"speech">>, <<"tts_cache">>}
         }
        ,{{<<"speech">>, <<"asr_prefered_content_type">>}
         ,{<<"speech">>, <<"asr_preferred_content_type">>}
         }

        ,{{<<"callflow">>, [<<"voicemail">>, <<"vm_message_foraward_type">>]}
         ,{<<"callflow">>, [<<"voicemail">>, <<"vm_message_forward_type">>]}
         }

        ,{<<"whapps_controller">>, <<"kapps_controller">>}
        ]).

-spec migrate() -> 'ok'.
migrate() ->
    lists:foreach(fun migrate_config_setting/1, ?CONFIG_MIGRATIONS).

-spec migrate_config_setting({migrate_setting(), migrate_setting()}) ->
                                    'ok' |
                                    {'error', any()}.
migrate_config_setting({?NE_BINARY = FromId, ?NE_BINARY = ToId}) ->
    migrate_config_doc(FromId, ToId);
migrate_config_setting({From, To}) ->
    lager:info("migrating ~p to ~p", [From, To]),
    case remove_config_setting(From) of
        {'ok', _, []} -> 'ok';
        {'ok', JObj, Removed} ->
            migrate_config_setting(JObj, Removed, To);
        {'error', 'not_found'} -> 'ok';
        {'error', Reason} -> {'error', {'remove', Reason}}
    end.

-spec migrate_config_setting(kz_json:object(), migrate_values(), migrate_setting()) ->
                                    'ok' |
                                    {'error', any()}.
migrate_config_setting(UpdatedFrom, Removed, {ToId, ToSetting}) ->
    case ToId =:= kz_doc:id(UpdatedFrom) of
        true ->
            case add_config_setting(UpdatedFrom, ToSetting, Removed) of
                {error, Reason} -> {error, {add, Reason}};
                {ok, Updated} ->
                    {ok, _} = kz_datamgr:save_doc(?KZ_CONFIG_DB, Updated),
                    ok
            end;
        false ->
            case add_config_setting(ToId, ToSetting, Removed) of
                {'error', Reason} -> {'error', {'add', Reason}};
                {'ok', UpdatedTo} ->
                    {'ok', _} = kz_datamgr:save_doc(?KZ_CONFIG_DB, UpdatedTo),
                    {'ok', _} = kz_datamgr:save_doc(?KZ_CONFIG_DB, UpdatedFrom),
                    'ok'
            end
    end.

-spec add_config_setting(kz_term:ne_binary(), config_key(), migrate_values()) ->
                                'ok' |
                                {'error', any()}.
add_config_setting(Id, Setting, Values) when is_binary(Id) ->
    case kz_datamgr:open_doc(?KZ_CONFIG_DB, Id) of
        {'ok', JObj} -> add_config_setting(JObj, Setting, Values);
        {'error', 'not_found'} ->
            New = kz_doc:update_pvt_parameters(kz_doc:set_id(kz_json:new(), Id)
                                              ,?KZ_CONFIG_DB
                                              ,[{'type', <<"config">>}]
                                              ),
            add_config_setting(New, Setting, Values);
        {'error', _}=Error -> Error
    end;
add_config_setting(JObj, _, []) -> {'ok', JObj};
add_config_setting(JObj, ToSetting, [{FromId, Node, FromSetting, Value} | Values]) ->
    ToId  = kz_doc:id(JObj),
    Key = config_setting_key(Node, ToSetting),
    case kz_json:get_value(Key, JObj) of
        'undefined' ->
            io:format("migrating setting from ~s ~s.~s to ~s ~s.~s value ~p~n"
                     ,[FromId, Node, FromSetting
                      ,ToId, Node, ToSetting
                      ,Value
                      ]),
            add_config_setting(kz_json:set_value(Key, Value, JObj)
                              ,ToSetting
                              ,Values
                              );
        Value -> add_config_setting(JObj, ToSetting, Values);
        _Else ->
            io:format("the system tried to move the parameter listed below"
                      " but found a different setting already there."
                      " You need to correct this disparity manually!~n"),
            io:format("  Source~n    db: ~s~n    id: ~s~n    key: ~s ~s~n    value: ~p~n"
                     ,[?KZ_CONFIG_DB, FromId, Node, FromSetting, Value]),
            io:format("  Destination~n    db: ~s~n    id: ~s~n    key: ~s ~s~n    value: ~p~n"
                     ,[?KZ_CONFIG_DB, ToId, Node, ToSetting, _Else]),
            {'error', 'disparity'}
    end.

-spec remove_config_setting(migrate_setting()) ->
                                   {'ok', kz_json:object(), migrate_values()} |
                                   {'error', any()}.
remove_config_setting({Id, Setting}) ->
    remove_config_setting(Id, Setting).

-spec remove_config_setting(kz_term:ne_binary() | kz_json:object(), config_key()) ->
                                   {'ok', kz_json:object(), migrate_values()} |
                                   {'error', any()}.
remove_config_setting(Id, Setting) when is_binary(Id) ->
    case kz_datamgr:open_doc(?KZ_CONFIG_DB, Id) of
        {'ok', JObj} -> remove_config_setting(JObj, Setting);
        {'error', _}=Error -> Error
    end;
remove_config_setting(JObj, Setting) ->
    Id = kz_doc:id(JObj),
    Keys = [{Id, Node, Setting}
            || Node <- kz_doc:get_public_keys(JObj),
               kz_json:is_json_object(Node, JObj)
           ],
    remove_config_setting(Keys, JObj, []).

-spec remove_config_setting([{kz_term:ne_binary(), kz_term:ne_binary(), config_key()}], kz_json:object(), migrate_values()) ->
                                   {'ok', kz_json:object(), migrate_values()}.
remove_config_setting([], JObj, Removed) ->
    {'ok', JObj, Removed};
remove_config_setting([{Id, Node, Setting} | Keys], JObj, Removed) ->
    Key = config_setting_key(Node, Setting),
    case kz_json:get_value(Key, JObj) of
        'undefined' -> remove_config_setting(Keys, JObj, Removed);
        Value ->
            remove_config_setting(Keys
                                 ,kz_json:delete_key(Key, JObj)
                                 ,[{Id, Node, Setting, Value} | Removed]
                                 )
    end.

-spec config_setting_key(kz_term:ne_binary(), config_key()) -> kz_term:ne_binaries().
%% NOTE: to support nested keys, update this merge function
config_setting_key(Node, Setting) when is_list(Setting) ->
    [Node | Setting];
config_setting_key(Node, Setting) ->
    [Node, Setting].

-spec migrate_config_doc(kz_term:ne_binary(), kz_term:ne_binary()) -> 'ok'.
migrate_config_doc(FromId, ToId) ->
    case kz_datamgr:open_doc(?KZ_CONFIG_DB, ToId) of
        {'ok', _ToJObj} ->
            lager:info("target doc ~s exists already, not migrating ~s", [ToId, FromId]);
        {'error', 'not_found'} ->
            case kz_datamgr:open_doc(?KZ_CONFIG_DB, FromId) of
                {'error', 'not_found'} -> lager:debug("didn't find ~s to migrate", [FromId]);
                {'ok', FromJObj} ->
                    migrate_from_doc_to_doc(FromJObj, base_to_doc(ToId))
            end
    end.

-spec migrate_from_doc_to_doc(kz_json:object(), kz_json:object()) -> 'ok'.
migrate_from_doc_to_doc(FromJObj, ToJObj) ->
    MigratedJObj = migrate_from_doc(FromJObj, ToJObj),
    {'ok', _ConfigDoc} = maybe_save_category(kz_doc:id(ToJObj), MigratedJObj, 'undefined'),
    lager:info("migrated ~s to ~s(~s)"
              ,[kz_doc:id(FromJObj), kz_doc:id(ToJObj), kz_doc:revision(_ConfigDoc)]
              ).

-spec migrate_from_doc(kz_json:object(), kz_json:object()) -> kz_json:object().
migrate_from_doc(FromJObj, ToJObj) ->
    kz_json:foldl(fun migrate_config_doc_node/3, ToJObj, kz_doc:public_fields(FromJObj, 'false')).

-spec migrate_config_doc_node(kz_term:ne_binary(), kz_json:object(), kz_json:object()) -> kz_json:object().
migrate_config_doc_node(FromNodeBefore, FromConfig, ToJObj) ->
    FromNode = maybe_fix_nodename(FromNodeBefore),
    kz_json:foldl(fun(ConfigKey, ConfigValue, Acc) ->
                          migrate_config_value(FromNode, ConfigKey, ConfigValue, Acc)
                  end
                 ,ToJObj
                 ,FromConfig
                 ).

-spec migrate_config_value(kz_term:ne_binary(), kz_term:ne_binary(), kz_json:json_term(), kz_json:object()) ->
                                  kz_json:object().
migrate_config_value(FromNode, <<"whapps">>, ConfigValue, ToJObj) ->
    kz_json:set_value([FromNode, <<"kapps">>], ConfigValue, ToJObj);
migrate_config_value(FromNode, ConfigKey, ConfigValue, ToJObj) ->
    kz_json:set_value([FromNode, ConfigKey], ConfigValue, ToJObj).

-spec maybe_fix_nodename(kz_term:ne_binary()) -> kz_term:ne_binary().
maybe_fix_nodename(<<"whistle_apps@", Host/binary>>) ->
    lager:info("changing whistle_apps@~s to kazoo_apps@~s", [Host, Host]),
    <<"kazoo_apps@", Host/binary>>;
maybe_fix_nodename(NodeName) ->
    NodeName.

-spec base_to_doc(kz_term:ne_binary()) -> kz_json:object().
base_to_doc(ToId) ->
    kz_json:from_list([{<<"_id">>, ToId}]).
