-- This file is part of pwd.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
expanded class XCLIP_PLUGIN

feature {ANY}
   is_native: BOOLEAN
      do
         Result := plugin_is_native /= 0
      end

   xclip (string: ABSTRACT_STRING)
      require
         string /= Void
      local
         s: POINTER
      do
         s := string.to_external
         plugin_copy(s)
      end

feature {}
   plugin_is_native: INTEGER
      external "plug_in"
      alias "{
         location: "."
         module_name: "plugin"
         feature_name: "xclip_native()"
      }"
      end

   plugin_copy (s: POINTER)
      external "plug_in"
      alias "{
         location: "."
         module_name: "plugin"
         feature_name: "xclip_copy"
      }"
      end

end -- class XCLIP_PLUGIN
