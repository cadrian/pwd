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
class XCLIP

inherit
   CLIPBOARD

create {CLIPBOARD_FACTORY}
   make

feature {ANY}
   copy (a_string: ABSTRACT_STRING) is
      local
         procs: FAST_ARRAY[PROCESS]
      do
         create procs.with_capacity(xclipboards.count)
         xclipboards.do_all(agent xclip_select(a_string, ?, procs))
         procs.do_all(agent {PROCESS}.wait)
      end

feature {}
   xclip_select (string: ABSTRACT_STRING; selection: STRING; procs: FAST_ARRAY[PROCESS]) is
      require
         procs /= Void
      local
         proc: PROCESS
      do
         proc := processor.execute(once "xclip", once "-selection #(1)" # selection)
         if proc.is_connected then
            proc.input.put_line(string)
            proc.input.disconnect
            procs.add_last(proc)
         end
      ensure
         procs.count = old procs.count + 1
      end

   xclipboards: FAST_ARRAY[STRING] is
      once
         Result := {FAST_ARRAY[STRING] << "primary", "clipboard" >>}
      end

feature {}
   make is
      do
      end

   processor: PROCESSOR

end
