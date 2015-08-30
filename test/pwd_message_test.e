-- This file is part of pwd.
-- Copyright (C) 2012-2015 Cyril Adrian <cyril.adrian@gmail.com>
--
-- pwd is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3 of the License.
--
-- pwd is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with pwd.  If not, see <http://www.gnu.org/licenses/>.
--
expanded class PWD_MESSAGE_TEST
   -- This class provides tools to test the JSON messages

insert
   PWD_TEST
   JSON_HANDLER

feature {}
   json (string: STRING): JSON_OBJECT
      require
         string /= Void
      local
         json_parser: JSON_PARSER; json_text: JSON_TEXT
      do
         create json_parser.make(agent on_error(?))
         json_text := json_parser.parse_json_text(create {STRING_INPUT_STREAM}.from_string(string))
         if Result ?:= json_text then
            Result ::= json_text
         else
            check
               last_error = Void
            end
            -- otherwise, json_text = Void and we cannot be here
            last_error := once "Not a JSON object!"
         end
      end

   on_error (err: like last_error)
      do
         last_error := err
      end

   last_error: ABSTRACT_STRING

end -- class PWD_MESSAGE_TEST
