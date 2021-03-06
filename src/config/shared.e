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
expanded class SHARED
   --
   -- A façade to the actual shared configuration
   --

insert
   TEST_FACADE[SHARED_DEF]

feature {ANY}
   server_pidfile: FIXED_STRING
      do
         Result := def.server_pidfile
      ensure
         Result /= Void
      end

   vault_file: FIXED_STRING
      do
         Result := def.vault_file
      ensure
         Result /= Void
      end

   log_file (tag: ABSTRACT_STRING): FIXED_STRING
      require
         tag /= Void
      do
         Result := def.log_file(tag)
      ensure
         Result /= Void
      end

   runtime_dir: FIXED_STRING
      do
         Result := def.runtime_dir
      ensure
         Result /= Void
      end

   log_level: FIXED_STRING
      do
         Result := def.log_level
      ensure
         Result /= Void
      end

   default_recipe: FIXED_STRING
      do
         Result := def.default_recipe
      ensure
         Result /= Void
      end

   channel_method: FIXED_STRING
      do
         Result := def.channel_method
      ensure
         Result /= Void
      end

   master_command: FIXED_STRING
      do
         Result := def.master_command
      ensure
         Result /= Void
      end

   master_arguments: FIXED_STRING
      do
         Result := def.master_arguments
      ensure
         Result /= Void
      end

feature {}
   def_impl: SHARED_IMPL
      once
         create Result
      end

end -- class SHARED
