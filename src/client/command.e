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
deferred class COMMAND

feature {CLIENT}
   name: FIXED_STRING is
      deferred
      end

   run (command: COLLECTION[STRING]) is
      require
         client /= Void
         command /= Void
      deferred
      end

   complete (command: COLLECTION[STRING]; word: FIXED_STRING): TRAVERSABLE[FIXED_STRING] is
      require
         client /= Void
         command /= Void
         word /= Void
      deferred
      end

feature {ANY}
   help (command: COLLECTION[STRING]): ABSTRACT_STRING is
         -- If `command' is Void, provide extended help
         -- Otherwise provide help depending on the user input
      require
         client /= Void
      deferred
      end

feature {}
   make (a_client: like client; map: DICTIONARY[COMMAND, FIXED_STRING]) is
      require
         a_client /= Void
         map /= Void
         not map.fast_has(name)
      do
         client := a_client
         map.add(Current, name)
      ensure
         client = a_client
         map.fast_at(name) = Current
      end

   client: CLIENT

invariant
   client /= Void

end
