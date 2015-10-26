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
deferred class REMOTE

insert
   CONFIGURABLE

feature {ANY}
   name: FIXED_STRING

   write_to (stream: OUTPUT_STREAM)
      require
         stream.is_connected
      deferred
      end

   save (local_file: ABSTRACT_STRING)
      require
         local_file /= Void
      deferred
      end

   load (local_file: ABSTRACT_STRING)
      require
         local_file /= Void
      deferred
      end

feature {COMMAND}
   set_property (key, value: ABSTRACT_STRING): BOOLEAN
         -- True if the property was set; False if unknown or could
         -- not be set
      require
         not key.is_empty
         not value.is_empty
      deferred
      end

   unset_property (key: ABSTRACT_STRING): BOOLEAN
         -- True if the property was unset; False if unknown or could
         -- not be unset
      require
         not key.is_empty
      deferred
      end

   has_proxy: BOOLEAN
         -- True if the remote can have a proxy (not necessarily if it
         -- actually has one)
      deferred
      end

   set_proxy_property (key, value: ABSTRACT_STRING): BOOLEAN
         -- True if the property was set; False if unknown or could
         -- not be set
      require
         has_proxy
         not key.is_empty
         not value.is_empty
      deferred
      end

   save_file
      local
         tfw: OUTPUT_STREAM
      do
         tfw := filesystem.connect_write(filename)
         if tfw /= Void then
            write_to(tfw)
            tfw.disconnect
         end
      end

   delete_file
      local
         path: FIXED_STRING
      do
         path := filename
         if filesystem.file_exists(path) then
            filesystem.delete(path)
         end
      end

feature {}
   processor: PROCESSOR

   xdg: XDG

   filename: FIXED_STRING
      do
         Result := (once "#(1)/#(2).rc" # xdg.config_home # name).intern
      end

   put_property (stream: OUTPUT_STREAM; property, value: ABSTRACT_STRING)
      require
         stream.is_connected
      do
         if value /= Void and then not value.is_empty then
            stream.put_line(once "#(1) = #(2)" # property # value)
         end
      end

   filesystem: FILESYSTEM

invariant
   name /= Void

end -- class REMOTE
