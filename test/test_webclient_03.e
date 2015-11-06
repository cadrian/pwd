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
         mock_process_decode, mock_process_encode: PROCESS_EXPECT
         decode_in, encode_in: STRING_OUTPUT_STREAM
         decode_out, encode_out: STRING_INPUT_STREAM
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

         vault_in := "test:1:0:pwd%N"
         expect_read("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault", vault_in)

         create mock_process_decode
         create decode_in.connect_to("")
         create decode_out.from_string("decode out")

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_processor.split_arguments__match(create {MOCK_STREQ}.make("TestOpensslCipher")).then_return({FAST_ARRAY[STRING] << "cipher" >>}),
            mock_processor.execute_redirect__match(create {MOCK_STREQ}.make("openssl"),
                                                   create {MOCK_STREQ}.make("cipher -d -a -pass env:VAULT_MASTER")).then_return(mock_process_decode.mock),
            mock_process_decode.is_connected.then_return(True),
            mock_process_decode.input.whenever.then_return(decode_in)
         >>})

         open_form := "<html><head><title>test</title></head><body><h1>This is a test!</h1></body></html>"
         expect_read("test/template/open_form.html", "#(1)%N" # open_form)

         expect_splice(Void, Void)

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_process_decode.output.whenever.then_return(decode_out),
            mock_process_decode.wait,
            mock_process_decode.status.then_return(0)
         >>})

         create mock_process_encode
         create encode_in.connect_to("")
         create encode_out.from_string("encode out")

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_filesystem.copy_to__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault"),
                                           create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault~")),
            mock_processor.split_arguments__match(create {MOCK_STREQ}.make("TestOpensslCipher")).then_return({FAST_ARRAY[STRING] << "cipher2" >>}),
            mock_processor.execute_redirect__match(create {MOCK_STREQ}.make("openssl"),
                                                   create {MOCK_STREQ}.make("cipher2 -a -pass env:VAULT_MASTER")).then_return(mock_process_encode.mock),
            mock_process_encode.is_connected.then_return(True),
            mock_process_encode.input.whenever.then_return(encode_in)
         >>})

         vault_out := ""
         create vault_output.connect_to(vault_out)

         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_process_encode.output.whenever.then_return(encode_out),
            mock_process_encode.wait,
            mock_process_encode.status.then_return(0),
            mock_processor.split_arguments__match(create {MOCK_STREQ}.make("Test/TemplatePath")).then_return({FAST_ARRAY[STRING] << "test/template" >>}),
            mock_filesystem.write_text__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/webclient-AAAAAAAAAAAAAAAA.vault")).then_return(vault_output)
         >>})

         expect_splice(encode_out, vault_output)

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