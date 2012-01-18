-- This file is part of pwdmgr.
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
class MENU

inherit
   CLIENT

create {}
   main

feature {}
   run is
      do
         send_menu
      end

   check_argument_count: BOOLEAN is True

   extra_args: STRING is " <dmenu args>"

   send_menu is
      require
         not fifo.exists(client_fifo)
      local
         tfr: TEXT_FILE_READ
      do
         fifo.make(client_fifo)
         send(once "menu #(1) #(2)" # client_fifo # menu_args)
         fifo.wait_for(client_fifo)
         create tfr.connect_to(client_fifo)
         if tfr.is_connected then
            tfr.read_line
            -- note: the server sends the name AND the password
            xclip(tfr.last_string.split.last)
            tfr.disconnect
            delete(client_fifo)
         end
      end

   menu_args: STRING is
      local
         i: INTEGER
      once
         from
            Result := ""
            i := 4
         until
            i > argument_count
         loop
            if i > 4 then
               Result.extend_unless(' ')
            end
            Result.append(argument(i))
            i := i + 1
         end
      end

end
