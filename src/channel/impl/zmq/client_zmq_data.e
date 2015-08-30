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
class CLIENT_ZMQ_DATA

inherit
   EZMQ_DATA

create {CLIENT_ZMQ}
   default_create

feature {CLIENT_ZMQ}
   when_reply: PROCEDURE[TUPLE[ABSTRACT_STRING]]
   on_timeout: PROCEDURE[TUPLE]
   timeout: PREDICATE[TUPLE]

   busy: BOOLEAN
      do
         Result := when_reply /= Void
         check
            Result = (on_timeout /= Void)
            Result = (timeout /= Void)
         end
      end

   set (wr: like when_reply; ot: like on_timeout; t: like timeout)
      require
         not busy
         wr /= Void
         ot /= Void
         t /= Void
      do
         when_reply := wr
         on_timeout := ot
         timeout := t
      ensure
         when_reply = wr
         on_timeout = ot
         timeout = t
         busy
      end

   clear
      require
         busy
      do
         when_reply := Void
         on_timeout := Void
         timeout := Void
      ensure
         not busy
      end

invariant
   busy implies when_reply /= Void
   busy implies on_timeout /= Void
   busy implies timeout /= Void

end -- class CLIENT_ZMQ_DATA
