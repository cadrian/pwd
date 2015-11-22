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
class TEST_JSON_FILE_01

insert
   PWD_TEST

create {}
   make

feature {}
   make
      local
         mock_vault_io: VAULT_IO_EXPECT
         json_file: JSON_FILE
         err: ABSTRACT_STRING; keys: HASHED_DICTIONARY[KEY, FIXED_STRING]
      do
         create mock_vault_io
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_vault_io.is_open.whenever.then_return(True),
            mock_vault_io.load__match(create {MOCK_ANY[FUNCTION[TUPLE[INPUT_STREAM], ABSTRACT_STRING]]}).with_side_effect(agent load("{}", ?))
         >>})
         scenario.replay_all

         create json_file
         create keys.make
         err := json_file.load(keys, mock_vault_io.mock)

         assert(err.is_empty)
         assert(keys.is_empty)
         scenario.check_all_done
      end

   load (s: ABSTRACT_STRING; args: MOCK_ARGUMENTS): ABSTRACT_STRING
      require
         s /= Void
      local
         loader: MOCK_TYPED_ARGUMENT[FUNCTION[TUPLE[INPUT_STREAM], ABSTRACT_STRING]]
         strin: STRING_INPUT_STREAM
      do
         loader ::= args.item(1)
         label_assert("loader must exist", loader /= Void)
         create strin.from_string(s)
         Result := loader.item.item([strin])
      end

end -- class TEST_JSON_FILE_01
