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
expanded class XCLIP_PLUGIN

feature {ANY}
   is_native: BOOLEAN is
      do
         Result := plugin_is_native /= 0
      end

   xclip (string: ABSTRACT_STRING) is
      require
         string /= Void
      local
         s: POINTER
      do
         s := string.to_external
         plugin_copy(s)
      end

feature {}
   plugin_is_native: INTEGER is
      external "plug_in"
      alias "{
         location: "."
         module_name: "plugin"
         feature_name: "xclip_native()"
      }"
      end

   plugin_copy (s: POINTER) is
      external "plug_in"
      alias "{
         location: "."
         module_name: "plugin"
         feature_name: "xclip_copy"
      }"
      end

end
