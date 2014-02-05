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
class MESSAGE_STREAMER

insert
   JSON_HANDLER
   LOGGING

create {ANY}
   make

feature {ANY}
   read_message (input: INPUT_STREAM) is
      require
         input.is_connected
      local
         json: JSON_TEXT; obj: JSON_OBJECT
      do
         last_message := Void
         error := Void
         json := parser.parse_json_text(input)
         if json = Void then
            -- no object (closed connection?)
         elseif error = Void then
            if not obj ?:= json then
               error := once "Malformed request"
            else
               obj ::= json
               last_message := factory.from_json(obj)
               if last_message = Void then
                  error := once "Invalid object"
               end
            end
         end
      ensure
         error /= Void implies last_message = Void
      end

   last_message: MESSAGE
   error: STRING

   write_message (message: MESSAGE; output: OUTPUT_STREAM) is
      require
         message /= Void
         output.is_connected
      do
         debug
            encoder.encode_in(message.json, log.trace)
            log.trace.put_new_line
         end
         encoder.encode_in(message.json, output)
      end

feature {}
   make is
      do
         create parser.make(agent json_parse_error(?))
         create encoder.make
      end

   json_parse_error (msg: ABSTRACT_STRING) is
      do
         error := msg.out
      end

   parser: JSON_PARSER
   encoder: JSON_ENCODER
   factory: MESSAGE_FACTORY

invariant
   parser /= Void
   encoder /= Void

end
