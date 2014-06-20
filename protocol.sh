#!/usr/bin/env bash

# TODO generate factory

dir=$(dirname $(readlink -f $0))

generate_const_arg() {
    type=$1
    shift
    if [ $# -gt 0 -o $type = reply ]; then
        echo -n " ("
        {
            if [ $type = reply ]; then
                echo "a_error: ABSTRACT_STRING"
            fi
            while [ $# -gt 0 ]; do
                echo "$1" | awk -F: '{print $1, $2}' | while read field type; do
                    echo -n a_$field": "
                    case $type in
                        STRING)
                            echo ABSTRACT_STRING
                            ;;
                        *)
                            echo $type
                            ;;
                    esac
                done
                shift
            done
        } | awk '{if (i) printf("; "); printf("%s", $0); i=1}'
        echo ")"
    fi
}

generate_extra_json() {
    while [ $# -gt 0 ]; do
        echo "$1" | awk -F: '{print $1, $2}' | while read field type; do
            case $type in
                STRING)
                    echo '            create {JSON_STRING}.from_string(a_'$field'), json_string(once "'$field'");'
                    ;;
                BOOLEAN)
                    echo '            json_boolean(a_'$field'), json_string(once "'$field'");'
                    ;;
                *)
                    echo '            -- ?? '$field
                    ;;
            esac
        done
        shift
    done
}

generate_getters() {
    while [ $# -gt 0 ]; do
        echo "$1" | awk -F: '{print $1, $2}' | while read field type; do
            echo
            echo "   $field: $type"
            echo "      do"
            case $type in
                STRING)
                    echo '         Result := string(once "'$field'")'
                    ;;
                BOOLEAN)
                    echo '         Result := {JSON_TRUE} ?:= json.members.reference_at(json_string(once "'$field'"))'
                    ;;
                *)
                    echo "         -- ??"
                    ;;
            esac
            echo "      end"
        done
        shift
    done
}

generate_require() {
    while [ $# -gt 0 ]; do
        echo "$1" | awk -F: '{print $1, $2}' | while read field type; do
            case $type in
                STRING)
                    echo '         a_'$field' /= Void'
                    ;;
                BOOLEAN)
                    ;;
                *)
                    echo "         -- ??"
                    ;;
            esac
        done
        shift
    done
}

generate() {
    name=$1
    type=$2
    shift 2
    classname=$(echo ${type}_${name} | tr '[a-z]' '[A-Z]')
    visitorname=$(echo ${type}_visitor | tr '[a-z]' '[A-Z]')

    echo "class $classname"
    echo "   -- Generated file, don't edit"
    echo "   -- Date: "$(date -R)
    echo
    echo "inherit"
    echo "   MESSAGE"
    echo
    echo "create {ANY}"
    echo "   make, from_json"
    echo
    echo "feature {ANY}"
    echo "   accept (visitor: VISITOR)"
    echo "      local"
    echo "         v: $visitorname"
    echo "      do"
    echo "         v ::= visitor"
    echo "         v.visit_$name(Current)"
    echo "      end"
    if [ $type = reply ]; then
        generate_getters error:STRING
    fi
    generate_getters "$@"
    echo
    echo "feature {}"
    echo "   make"$(generate_const_arg $type "$@")
    echo "      require"
    if [ $type = reply ]; then
        echo "         a_error /= Void"
    fi
    generate_require "$@"
    echo "      do"
    echo "         create json.make({HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] <<"
    echo "            json_string(once "'"'$type'"), json_string(once "type");'
    echo "            json_string(once "'"'$name'"), json_string(once "command");'
    if [ $type = reply ]; then
        echo '            json_string(a_error), json_string(once "error");'
    fi
    generate_extra_json "$@"
    echo "         >>})"
    echo "      end"
    echo
    echo "end"
}

generate_visitor() {
    type=$1
    visitorname=$(echo ${type}_visitor | tr '[a-z]' '[A-Z]')
    shift
    echo "deferred class $visitorname"
    echo "   -- Generated file, don't edit"
    echo "   -- Date: "$(date -R)
    echo
    echo "inherit"
    echo "   VISITOR"
    while [ $# -gt 0 ]; do
        name=$1
        classname=$(echo ${type}_${name} | tr '[a-z]' '[A-Z]')
        echo
        echo "feature {$classname}"
        echo "   visit_$name ($type: $classname)"
        echo "      require"
        echo "         $type /= Void"
        echo "      deferred"
        echo "      end"
        shift
    done
    echo
    echo "end"
}

generate_factory() {
    echo "expanded class MESSAGE_FACTORY"
    echo "   -- Generated file, don't edit"
    echo "   -- Date: "$(date -R)
    echo
    echo "insert"
    echo "   JSON_HANDLER"
    echo "   LOGGING"
    echo
    echo "feature {ANY}"
    echo "   from_json (json: JSON_OBJECT): MESSAGE"
    echo "      local"
    echo "         type, command: JSON_STRING"
    echo "      do"
    echo "         if json /= Void and then json.members.has(json_type) and then json.members.has(json_command) then"
    echo "            type ::= json.members.at(json_type)"
    echo "            command ::= json.members.at(json_command)"
    echo
    echo '            log.trace.put_line("Building command %"#(1)%" (type %"#(2)%")" # command.string.to_utf8 # type.string.to_utf8)'
    echo
    echo "            inspect"
    echo "               command.string.as_utf8"
    while [ $# -gt 0 ]; do
        command=$1
        echo '            when "'"$command"'" then'
        echo "               inspect"
        echo "                  type.string.as_utf8"
        echo '               when "query" then'
        echo "                  create {QUERY_"$(echo $command | tr '[a-z]' '[A-Z]')"} Result.from_json(json)"
        echo '               when "reply" then'
        echo "                  create {REPLY_"$(echo $command | tr '[a-z]' '[A-Z]')"} Result.from_json(json)"
        echo "               end"
        shift
    done
    echo "            end"
    echo "         end"
    echo "      end"
    echo
    echo "feature {}"
    echo "   json_type: JSON_STRING"
    echo "      once"
    echo '         create Result.from_string("type")'
    echo "      end"
    echo
    echo "   json_command: JSON_STRING"
    echo "      once"
    echo '         create Result.from_string("command")'
    echo "      end"
    echo
    echo "end"
}

describe() {
    if [ x. != x"$1" ]; then
        echo "$1" | sed 's/|/\n/g'
    fi
}

grep -v '^#' $dir/src/protocol/messages.rc | while read name desc_query desc_reply; do
    if [ "$desc_query" != "!" ]; then
        generate $name query $(describe $desc_query) > $dir/src/protocol/query_$name.e
    fi
    if [ "$desc_reply" != "!" ]; then
        generate $name reply $(describe $desc_reply) > $dir/src/protocol/reply_$name.e
    fi
done

generate_visitor query $(grep -v '^#' $dir/src/protocol/messages.rc | awk '{print $1}') > $dir/src/protocol/query_visitor.e
generate_visitor reply $(grep -v '^#' $dir/src/protocol/messages.rc | awk '{print $1}') > $dir/src/protocol/reply_visitor.e

generate_factory $(grep -v '^#' $dir/src/protocol/messages.rc | awk '{print $1}') > $dir/src/protocol/message_factory.e
