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
class JSON_CLEANER

inherit
   JSON_VISITOR

insert
   ARRAYED_COLLECTION_HANDLER
   UNICODE_STRING_HANDLER

feature {JSON_ARRAY}
   visit_array (json: JSON_ARRAY)
      local
         i: INTEGER
      do
         from
            i := json.lower
         until
            i > json.upper
         loop
            json.item(i).accept(Current)
            i := i + 1
         end
      end

feature {JSON_FALSE}
   visit_false (json: JSON_FALSE)
      do
      end

feature {JSON_NULL}
   visit_null (json: JSON_NULL)
      do
      end

feature {JSON_NUMBER}
   visit_number (json: JSON_NUMBER)
      do
      end

feature {JSON_OBJECT}
   visit_object (json: JSON_OBJECT)
      local
         i: INTEGER
      do
         from
            i := json.members.lower
         until
            i > json.members.upper
         loop
            -- Don't clean keys (the map would be incoherent)
            -- That's ok because keys don't hold sensitive information
            json.members.item(i).accept(Current)
            i := i + 1
         end
      end

feature {JSON_STRING}
   visit_string (json: JSON_STRING)
      local
         s: UNICODE_STRING; i, c: INTEGER
      do
         json.invalidate
         s := json.string
         check
            s.capacity > 0
         end
         s.clear_count
         c := bzero.secure_max(s.capacity)
         if s.low_surrogate_indexes.capacity > 0 then
            c := bzero.secure_max(s.low_surrogate_indexes.capacity)
         end
         if s.low_surrogate_values.capacity > 0 then
            c := bzero.secure_max(s.low_surrogate_values.capacity)
         end

         --|**** TODO: Not as secure as BZERO. Should it be?
         from
            i := 0
         until
            i >= c
         loop
            s.storage.put(0, i \\ s.capacity)
            if s.low_surrogate_indexes.capacity > 0 then
               s.low_surrogate_indexes.storage.put(0, i \\ s.low_surrogate_indexes.capacity)
            end
            if s.low_surrogate_values.capacity > 0 then
               s.low_surrogate_values.storage.put(0, i \\ s.low_surrogate_values.capacity)
            end
            i := i + 1
         end
      end

feature {JSON_TRUE}
   visit_true (json: JSON_TRUE)
      do
      end

feature {}
   bzero: BZERO

end -- class JSON_CLEANER
