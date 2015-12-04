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
class TEST_WEBCLIENT_03

insert
   ABSTRACT_TEST_WEBCLIENT

create {}
   make

feature {}
   make
      local
         mock_json_file_provider: JSON_FILE_PROVIDER_EXPECT
         mock_vault_file_load, mock_vault_file_save: VAULT_FILE_EXPECT
         open_form: STRING
         flock: FILE_LOCKER
         mock_flock: FILE_LOCKER_EXPECT
         mock_lock_file: TERMINAL_OUTPUT_STREAM_EXPECT
         mock_lock: FILE_LOCK_EXPECT
         is_connected, lock: REFERENCE[BOOLEAN]
      do
         prepare_test
         expect_random

         create mock_json_file_provider
         json_file_provider.set_def(mock_json_file_provider.mock)

         create mock_vault_file_load
         create mock_vault_file_save

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_json_file_provider.new.then_return(agent: VAULT_FILE then mock_vault_file_load.mock end),
            mock_processor.split_arguments__match(create {MOCK_STREQ}.make("Test/TemplatePath")).then_return({FAST_ARRAY[STRING] << "test/template" >>})
         >>})

         create mock_flock
         flock.set_def(mock_flock.mock)
         create mock_lock_file
         create mock_lock
         create is_connected
         create lock

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_filesystem.file_exists__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault")).whenever.then_return(False),
            mock_filesystem.write_text__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault.lock")).whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS): TERMINAL_OUTPUT_STREAM do is_connected.item := True then mock_lock_file.mock end (?)),
            mock_lock_file.filtered_has_descriptor.whenever.then_return(True),
            mock_lock_file.filtered_descriptor.whenever.then_return(42),
            mock_flock.lock(mock_lock_file.mock).then_return(mock_lock.mock),
            mock_lock.write
               .with_side_effect(agent (arg: MOCK_ARGUMENTS) do lock.item := True end (?)),
            mock_lock.write_locked.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS): BOOLEAN then lock.item end (?)),
            mock_lock.read_locked.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS): BOOLEAN then lock.item end (?)),
            mock_lock.locked.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS): BOOLEAN then lock.item end (?)),
            mock_environment.set_variable("VAULT_MASTER", "testuser!AAAAAAAAAAAAAAAA"),
            mock_environment.set_variable("VAULT_MASTER", ""),
            mock_environment.set_variable("VAULT_MASTER", "testuser!AAAAAAAAAAAAAAAA"),
            mock_environment.set_variable("VAULT_MASTER", ""),
            mock_lock.done
               .with_side_effect(agent (arg: MOCK_ARGUMENTS) do lock.item := False end (?)),
            mock_lock_file.is_connected.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS): BOOLEAN then is_connected.item end (?)),
            mock_lock_file.disconnect
               .with_side_effect(agent (arg: MOCK_ARGUMENTS) do is_connected.item := False end (?))
         >>})

         open_form := "<html><head><title>test</title></head><body><h1>This is a test!</h1></body></html>"
         expect_read("test/template/open_form.html", "#(1)%N" # open_form)
         expect_splice(Void, Void)

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_json_file_provider.new.then_return(agent: VAULT_FILE then mock_vault_file_save.mock end),
            mock_vault_file_save.save__match(create {MOCK_ANY[DICTIONARY[KEY, FIXED_STRING]]},
                                             create {MOCK_ANY[VAULT_IO]}).then_return("")
         >>})

         assert(call_cgi("GET", "/open").is_equal("Content-Type:text/html%R%N%
                                                  %Cache-Control:%"private,no-store,no-cache%"%R%N%
                                                  %Set-Cookie:sessionvault=AAAAAAAAAAAAAAAA; Max-Age=14400; Secure%R%N%
                                                  %%R%N%
                                                  %#(1)%R%N" # open_form))

         assert(scenario.missing_expectations.is_empty)
      end

   json_file_provider: JSON_FILE_PROVIDER

end -- class TEST_WEBCLIENT_03
