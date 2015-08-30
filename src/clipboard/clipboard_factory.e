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
expanded class CLIPBOARD_FACTORY

insert
   XCLIP_PLUGIN

feature {ANY}
   new_clipboard: CLIPBOARD
      do
         if is_native then
            create {XCLIP_NATIVE} Result.make
         else
            create {XCLIP} Result.make
         end
      ensure
         Result /= Void
      end

end -- class CLIPBOARD_FACTORY
