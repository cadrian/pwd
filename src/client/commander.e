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
expanded class COMMANDER

feature {}
   commands: MAP[COMMAND, FIXED_STRING]

   add_help (a_msg: STRING)
      require
         a_msg /= Void
      do
         commands.do_all_items(agent (msg: STRING; cmd: COMMAND)
      local
         h: ABSTRACT_STRING
            do
               h := cmd.help(Void)
               if h /= Void then
                  msg.extend('%N')
                  msg.append(h)
               end
            end(a_msg, ?))
      end

invariant
   commands /= Void

end -- class COMMANDER
