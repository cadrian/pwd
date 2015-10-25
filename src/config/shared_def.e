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
deferred class SHARED_DEF

inherit
   TESTABLE

feature {SHARED}
   server_pidfile: FIXED_STRING
      deferred
      end

   vault_file: FIXED_STRING
      deferred
      end

   log_file (tag: ABSTRACT_STRING): FIXED_STRING
      require
         tag /= Void
      deferred
      end

   runtime_dir: FIXED_STRING
      deferred
      end

   log_level: FIXED_STRING
      deferred
      end

   default_recipe: FIXED_STRING
      deferred
      end

   channel_method: FIXED_STRING
      deferred
      end

   master_command: FIXED_STRING
      deferred
      end

   master_arguments: FIXED_STRING
      deferred
      end

end -- class SHARED_DEF
