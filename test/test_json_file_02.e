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
class TEST_JSON_FILE_02
   --
   -- Test JSON file with keys loading
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
         err: ABSTRACT_STRING; keys: HASHED_DICTIONARY[KEY, FIXED_STRING]
         key: KEY
      do
         create mock_vault_io
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_vault_io.is_open.whenever.then_return(True),
            mock_vault_io.exists.whenever.then_return(True),
            mock_vault_io.load__match(create {MOCK_ANY[FUNCTION[TUPLE[INPUT_STREAM], ABSTRACT_STRING]]}).with_side_effect(agent load("{%"foo%":{%"name%":%"foo%",%"pass%":%"foopass%",%"add_count%":0,%"del_count%":0},%"bar%":{%"name%":%"bar%",%"pass%":%"barpass%",%"add_count%":1,%"del_count%":2,%"properties%":{%"username%":%"user_bar%",%"url%":%"http://localhost:8080%"}},%"baz%":{%"name%":%"baz%",%"pass%":%"bazpass%",%"add_count%":0,%"del_count%":0,%"properties%":{%"tags%":%"THIS THAT%"}}}", ?))
         >>})
         scenario.replay_all

         create json_file
         create keys.make
         err := json_file.load(keys, mock_vault_io.mock)

         assert(err.is_empty)
         assert(keys.count = 3)
         assert(keys.fast_has("foo".intern))
         assert(keys.fast_has("bar".intern))
         assert(keys.fast_has("baz".intern))

         key := keys.fast_at("foo".intern)
         assert(key.name = "foo".intern)
         assert(key.pass.is_equal("foopass"))
         assert(key.add_count = 0)
         assert(key.del_count = 0)
         assert(key.username = Void)
         assert(key.url = Void)
         assert(key.tags.is_empty)

         key := keys.fast_at("bar".intern)
         assert(key.name = "bar".intern)
         assert(key.pass.is_equal("barpass"))
         assert(key.add_count = 1)
         assert(key.del_count = 2)
         assert(key.username.is_equal("user_bar"))
         assert(key.url.is_equal("http://localhost:8080"))
         assert(key.tags.is_empty)

         key := keys.fast_at("baz".intern)
         assert(key.name = "baz".intern)
         assert(key.pass.is_equal("bazpass"))
         assert(key.add_count = 0)
         assert(key.del_count = 0)
         assert(key.username = Void)
         assert(key.url = Void)
         assert(key.tags.count = 2)
         assert(key.tags.fast_has("THIS".intern))
         assert(key.tags.fast_has("THAT".intern))

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
      then
         loader.item.item([strin])
      end

end -- class TEST_JSON_FILE_02
