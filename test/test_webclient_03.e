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
         open_form, vault_in, vault_out: STRING; now: TIME
         flock: FILE_LOCKER
         mock_flock: FILE_LOCKER_EXPECT
         mock_lock_file: TERMINAL_OUTPUT_STREAM_EXPECT
         mock_lock: FILE_LOCK_EXPECT
         vault_output: STRING_OUTPUT_STREAM
      do
         prepare_test
         expect_splice(Void, Void)
         expect_random

         now.update

         create mock_flock
         flock.set_def(mock_flock.mock)
         create mock_lock_file
         create mock_lock

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_filesystem.file_exists__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault")).then_return(False),
            mock_filesystem.write_text__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault.lock")).whenever.then_return(mock_lock_file.mock),
            mock_lock_file.filtered_has_descriptor.whenever.then_return(True),
            mock_lock_file.filtered_descriptor.whenever.then_return(42),
            mock_flock.lock(mock_lock_file.mock).then_return(mock_lock.mock),
            mock_lock.write,
            mock_environment.set_variable("VAULT_MASTER", "testuser!AAAAAAAAAAAAAAAA"),
         >>})

         vault_in := "test vault"
         expect_read("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault", vault_in)

         open_form := "<html><head><title>test</title></head><body><h1>This is a test!</h1></body></html>"
         expect_read("Test/TemplatePath/open_form.html", "#(1)%N" # open_form)

         expect_splice(Void, Void)

         vault_out := ""
         create vault_output.connect_to(vault_out)

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_filesystem.copy_to__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault"),
                                           create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault~")),
            mock_filesystem.write_text__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault")).then_return(vault_output)
         >>})

         expect_splice(Void, vault_output)

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_environment.set_variable("VAULT_MASTER", ""),
            mock_lock.done,
            mock_lock_file.disconnect,
            mock_lock_file.is_connected.whenever.then_return(False)
         >>})

         scenario.replay_all
         assert(call_cgi("GET", "/open").is_equal("Content-Type:text/html%R%N%
                                                  %Cache-Control:%"private,no-store,no-cache%"%R%N%
                                                  %Set-Cookie:sessionvault=AAAAAAAAAAAAAAAA; Max-Age=14400; Secure%R%N%
                                                  %%R%N%
                                                  %#(1)%R%N" # open_form))

         assert(scenario.missing_expectations.is_empty)
      end

end -- class TEST_WEBCLIENT_03
