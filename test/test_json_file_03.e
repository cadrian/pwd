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
class TEST_JSON_FILE_03
   --
   -- Test JSON file writing
   --

insert
   PWD_TEST
   KEY_HANDLER

create {}
   make

feature {}
   make
      local
         mock_vault_io: VAULT_IO_EXPECT
         json_file: JSON_FILE
         err: ABSTRACT_STRING; keys: DICTIONARY[KEY, FIXED_STRING]
      do
         create mock_vault_io

         keys := {LINKED_HASHED_DICTIONARY[KEY, FIXED_STRING] <<
            create {KEY}.from_file("foo", "foopass", 2, 2), "foo".intern;
            create {KEY}.from_file("bar", "barpass", 0, 3), "bar".intern
         >> }

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_vault_io.is_open.whenever.then_return(True),
            mock_vault_io.exists.whenever.then_return(True),
            mock_vault_io.save__match(create {MOCK_ANY[FUNCTION[TUPLE[OUTPUT_STREAM], ABSTRACT_STRING]]},
                                      create {MOCK_ANY[FUNCTION[TUPLE[ABSTRACT_STRING], ABSTRACT_STRING]]})
               .with_side_effect(agent save(?))
         >>})
         scenario.replay_all

         create json_file

         err := json_file.save(keys, mock_vault_io.mock)

         assert(err.is_empty)
         assert(json_out.is_equal("{%"foo%":{%"name%":%"foo%",%"pass%":%"foopass%",%"add_count%":2,%"del_count%":2},%"bar%":{%"name%":%"bar%",%"pass%":%"barpass%",%"add_count%":0,%"del_count%":3}}"))

         scenario.check_all_done
      end

   save (args: MOCK_ARGUMENTS): ABSTRACT_STRING
      local
         saver: MOCK_TYPED_ARGUMENT[FUNCTION[TUPLE[OUTPUT_STREAM], ABSTRACT_STRING]]
         on_save: MOCK_TYPED_ARGUMENT[FUNCTION[TUPLE[ABSTRACT_STRING], ABSTRACT_STRING]]
         strout: STRING_OUTPUT_STREAM
      do
         saver ::= args.item(1)
         on_save ::= args.item(2)
         label_assert("saver must exist", saver /= Void)
         label_assert("on_save must exist", on_save /= Void)
         json_out := ""
         create strout.connect_to(json_out)
         Result := on_save.item.item([saver.item.item([strout])])
      end

   json_out: STRING

end -- class TEST_JSON_FILE_03
