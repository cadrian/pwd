-- This file is part of pwdmgr.
-- Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>
--
-- pwdmgr is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3 of the License.
--
-- pwdmgr is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with pwdmgr.  If not, see <http://www.gnu.org/licenses/>.
--
expanded class MESSAGE_FACTORY

insert
   JSON_HANDLER
   LOGGING

feature {ANY}
   from_json (json: JSON_OBJECT): MESSAGE is
      local
         type, command: JSON_STRING
      do
         if json /= Void and then json.members.has(json_type) and then json.members.has(json_command) then
            type ::= json.members.at(json_type)
            command ::= json.members.at(json_command)

            log.trace.put_line("MESSAGE_FACTORY: command '#(1)' type '#(2)'" # command.string.to_utf8 # type.string.to_utf8)

            inspect
               command.string.as_utf8
            when "ping" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_PING} Result.from_json(json)
               when "reply" then
                  create {REPLY_PING} Result.from_json(json)
               end
            when "master" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_MASTER} Result.from_json(json)
               when "reply" then
                  create {REPLY_MASTER} Result.from_json(json)
               end
            when "list" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_LIST} Result.from_json(json)
               when "reply" then
                  create {REPLY_LIST} Result.from_json(json)
               end
            when "get" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_GET} Result.from_json(json)
               when "reply" then
                  create {REPLY_GET} Result.from_json(json)
               end
            when "set" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_SET} Result.from_json(json)
               when "reply" then
                  create {REPLY_SET} Result.from_json(json)
               end
            when "unset" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_UNSET} Result.from_json(json)
               when "reply" then
                  create {REPLY_UNSET} Result.from_json(json)
               end
            when "save" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_SAVE} Result.from_json(json)
               when "reply" then
                  create {REPLY_SAVE} Result.from_json(json)
               end
            when "merge" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_MERGE} Result.from_json(json)
               when "reply" then
                  create {REPLY_MERGE} Result.from_json(json)
               end
            when "close" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_CLOSE} Result.from_json(json)
               when "reply" then
                  create {REPLY_CLOSE} Result.from_json(json)
               end
            when "stop" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_STOP} Result.from_json(json)
               when "reply" then
                  create {REPLY_STOP} Result.from_json(json)
               end
            when "is_open" then
               inspect
                  type.string.as_utf8
               when "query" then
                  create {QUERY_IS_OPEN} Result.from_json(json)
               when "reply" then
                  create {REPLY_IS_OPEN} Result.from_json(json)
               end
            end
         end
      end

feature {}
   json_type: JSON_STRING is
      once
         create Result.from_string("type")
      end

   json_command: JSON_STRING is
      once
         create Result.from_string("command")
      end

end
