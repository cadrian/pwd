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
deferred class TEST_FACADE[T_ -> TESTABLE]
   --
   -- Test version of "testable" objects
   --

feature {ANY}
   set_def (a_def: like def)
         -- Only for tests
      require
         a_def /= Void
      do
         def_memory.set_item(a_def)
      ensure
         def = a_def
      end

feature {}
   def: T_
      local
         ref: REFERENCE[T_]
      do
         ref := def_memory
         Result := ref.item
         if Result = Void then
            Result := def_impl
            set_def(Result)
         end
      ensure
         Result /= Void
         idempotent: def = Result
      end

   def_memory: REFERENCE[T_]
      do
         Result ::= def_map.reference_at(generating_type)
         if Result = Void then
            create Result
            def_map.put(Result, generating_type)
         end
      ensure
         idempotent: def_memory = Result
      end

   def_impl: T_
      deferred
      ensure
         Result /= Void
      end

   def_map: HASHED_DICTIONARY[REFERENCE[TESTABLE], STRING]
      once
         create Result
      ensure
         Result /= Void
      end

end -- class TEST_FACADE
