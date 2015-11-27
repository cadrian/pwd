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
deferred class ABSTRACT_TEST_WEBCLIENT

insert
   EIFFELTEST_TOOLS

feature {}
   prepare_test
      local
         channel_factory: CHANNEL_FACTORY
         shared: SHARED
         extern: EXTERN
         filesystem: FILESYSTEM
         environment: ENVIRONMENT
         processor: PROCESSOR
         any_string: MOCK_ANY[ABSTRACT_STRING]
      do
         create any_string
         create mock_extern
         extern.set_def(mock_extern.mock)
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_extern.tmp.whenever.then_return(tmpdir)
         >>})

         create mock_shared
         shared.set_def(mock_shared.mock)
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_shared.log_file("webclient").whenever.then_return(logfile),
            mock_shared.log_level.whenever.then_return(loglevel),
            mock_shared.server_pidfile.whenever.then_return(pidfile),
            mock_shared.vault_file.whenever.then_return(vaultfile),
            mock_shared.runtime_dir.whenever.then_return(runtimedir)
         >>})

         create mock_channel_factory
         channel_factory.set_def(mock_channel_factory.mock)
         create mock_client_channel
         create mock_server_channel
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_channel_factory.new_client_channel(tmpdir).whenever.then_return(mock_client_channel.mock),
--            mock_channel_factory.new_server_channel.then_return(mock_server_channel.mock)
         >>})

         create mock_filesystem
         filesystem.set_def(mock_filesystem.mock)
         create mock_environment
         environment.set_def(mock_environment.mock)
         create mock_processor
         processor.set_def(mock_processor.mock)
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_environment.variable("XDG_CONFIG_HOME").whenever.then_return("XDG_CONFIG_HOME"),
            mock_environment.variable("XDG_CONFIG_DIRS").whenever.then_return("XDG_CONFIG_DIRS"),
            mock_environment.variable("XDG_CACHE_HOME").whenever.then_return("XDG_CACHE_HOME"),
            mock_filesystem.file_exists__match(any_string).then_return(True),
            mock_filesystem.is_directory__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME/.cache/pwd")).whenever.then_return(True),
            mock_filesystem.is_directory__match(create {MOCK_STREQ}.make("XDG_CACHE_HOME")).whenever.then_return(True)
         >>})
         expect_read("XDG_CONFIG_HOME/pwd/config.rc", "[
            [webclient]
            static.path: Test/StaticPath
            template.path: Test/TemplatePath

            [vault]
            openssl.cipher: TestOpensslCipher

         ]")

         -- Mock expectations for channels start, server start...
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<

            mock_client_channel.is_ready.whenever.then_return(True),

            mock_client_channel.server_running__match(create {MOCK_ANY[PROCEDURE[TUPLE[BOOLEAN]]]}).whenever
               .with_side_effect(agent (args: MOCK_ARGUMENTS)
                                    local
                                       when_reply: MOCK_TYPED_ARGUMENT[PROCEDURE[TUPLE[BOOLEAN]]]
                                    do
                                       when_reply ::= args.item(1)
                                       when_reply.item.call([True])
                                    end(?)),

            mock_client_channel.call__match(create {MOCK_EQ[MESSAGE]}.make(create {QUERY_VERSION}.make), create {MOCK_ANY[PROCEDURE[TUPLE[MESSAGE]]]}).whenever
               .with_side_effect(agent (args: MOCK_ARGUMENTS)
                                    local
                                       when_reply: MOCK_TYPED_ARGUMENT[PROCEDURE[TUPLE[MESSAGE]]]
                                       v: VERSION
                                    do
                                       when_reply ::= args.item(2)
                                       when_reply.item.call([create {REPLY_VERSION}.make("", v.version)])
                                    end(?)),

            mock_client_channel.call__match(create {MOCK_EQ[MESSAGE]}.make(create {QUERY_IS_OPEN}.make), create {MOCK_ANY[PROCEDURE[TUPLE[MESSAGE]]]}).whenever
               .with_side_effect(agent (args: MOCK_ARGUMENTS)
                                    local
                                       when_reply: MOCK_TYPED_ARGUMENT[PROCEDURE[TUPLE[MESSAGE]]]
                                    do
                                       when_reply ::= args.item(2)
                                       when_reply.item.call([create {REPLY_IS_OPEN}.make("", True)])
                                    end(?)),

            mock_client_channel.cleanup.whenever

         >>})
      end

   tmpdir: FIXED_STRING
      once
         Result := "tmpdir".intern
      end

   logfile: FIXED_STRING
      once
         Result := ("#(1).log" # generating_type).intern
      end

   pidfile: FIXED_STRING
      once
         Result := "pidfile".intern
      end

   loglevel: FIXED_STRING
      once
         Result := "trace".intern
      end

   vaultfile: FIXED_STRING
      once
         Result := "vaultfile".intern
      end

   runtimedir: FIXED_STRING
      once
         Result := "runtimedir".intern
      end

   mock_shared: SHARED_EXPECT
   mock_extern: EXTERN_EXPECT
   mock_channel_factory: CHANNEL_FACTORY_EXPECT
   mock_client_channel: CLIENT_CHANNEL_EXPECT
   mock_server_channel: SERVER_CHANNEL_EXPECT
   mock_filesystem: FILESYSTEM_EXPECT
   mock_environment: ENVIRONMENT_EXPECT
   mock_processor: PROCESSOR_EXPECT

   expect_splice (input: TERMINAL_INPUT_STREAM; output: TERMINAL_OUTPUT_STREAM)
      do
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_extern.splice__match(create {MOCK_ANY[INPUT_STREAM]}, create {MOCK_ANY[OUTPUT_STREAM]})
               .with_side_effect(agent (args: MOCK_ARGUMENTS; expected_input: TERMINAL_INPUT_STREAM; expected_output: TERMINAL_OUTPUT_STREAM)
                                    local
                                       actual_input_arg: MOCK_TYPED_ARGUMENT[INPUT_STREAM]
                                       actual_output_arg: MOCK_TYPED_ARGUMENT[OUTPUT_STREAM]
                                       actual_input: INPUT_STREAM
                                       actual_output: OUTPUT_STREAM
                                    do
                                       actual_input_arg ::= args.item(1)
                                       actual_output_arg ::= args.item(2)

                                       actual_input := actual_input_arg.item
                                       actual_output := actual_output_arg.item

                                       label_assert("actual_input must exist", actual_input /= Void)
                                       label_assert("actual_output must exist", actual_output /= Void)
                                       label_assert("actual_input must match expected_input", expected_input /= Void implies expected_input = actual_input)
                                       label_assert("actual_output must match expected_output", expected_output /= Void implies expected_output = actual_output)

                                       from
                                          actual_input.read_line
                                       until
                                          actual_input.end_of_input
                                       loop
                                          actual_output.put_line(actual_input.last_string)
                                          actual_input.read_line
                                       end
                                       actual_output.put_string(actual_input.last_string)
                                       actual_output.flush
                                    end(?, input, output))
         >>})
      end

   expect_read (filename, content: ABSTRACT_STRING)
      require
         filename /= Void
         content /= Void
      local
         input: STRING_INPUT_STREAM
      do
         create input.from_string(content)
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_filesystem.read_text__match(create {MOCK_STREQ}.make(filename)).whenever.then_return(input)
         >>})
      end

   expect_random
      local
         mock_random: BINARY_INPUT_STREAM_EXPECT
         is_connected: REFERENCE[BOOLEAN]
      do
         create is_connected
         create mock_random
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<
            mock_filesystem.read_binary__match(create {MOCK_STREQ}.make("/dev/urandom")).whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS; iscon: REFERENCE[BOOLEAN]): BINARY_INPUT_STREAM
                                    do
                                       iscon.item := True
                                       Result := mock_random.mock
                                    end (?, is_connected)),
            mock_random.is_connected.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS; iscon: REFERENCE[BOOLEAN]): BOOLEAN
                                    do
                                       Result := iscon.item
                                    end (?, is_connected)),
            mock_random.can_read_character.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS; iscon: REFERENCE[BOOLEAN]): BOOLEAN
                                    do
                                       Result := iscon.item
                                    end (?, is_connected)),
            mock_random.end_of_input.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS; iscon: REFERENCE[BOOLEAN]): BOOLEAN
                                    do
                                       Result := not iscon.item
                                    end (?, is_connected)),
            mock_random.can_disconnect.whenever.then_return(True),
            mock_random.read_byte.whenever,
            mock_random.last_byte.whenever.then_return(0),
            mock_random.disconnect.whenever
               .with_side_effect(agent (arg: MOCK_ARGUMENTS; iscon: REFERENCE[BOOLEAN])
                                    do
                                       iscon.item := False
                                    end (?, is_connected))
         >>})
      end

feature {}
   client: WEBCLIENT

   call_cgi (method, path: STRING): STRING
      local
         system: SYSTEM; cgi: CGI_IO
         sos: STRING_OUTPUT_STREAM
      do
         scenario.replay_all

         system.set_environment_variable("REQUEST_METHOD", method)
         system.set_environment_variable("REMOTE_USER", "testuser")
         system.set_environment_variable("PATH_INFO", path)
         system.set_environment_variable("SERVER_NAME", "testserver")
         system.set_environment_variable("SERVER_PORT", "443")
         system.set_environment_variable("SERVER_PROTOCOL", "HTTP/1.1")
         system.set_environment_variable("SERVER_SOFTWARE", "eiffeltest")
         system.set_environment_variable("HTTPS", "on")
         system.set_environment_variable("HTTP_HOST", "test.server.net:8943")

         Result := ""
         create sos.connect_to(Result)
         cgi.set_output(sos)

         create client.make

         sedb_breakpoint

         scenario.check_all_done
      end

   read_file (file: STRING): STRING
      local
         tfr: TEXT_FILE_READ
      do
         create tfr.connect_to(file)
         if tfr.is_connected then
            from
               Result := ""
               tfr.read_line
            until
               tfr.end_of_input
            loop
               Result.append(tfr.last_string)
               Result.extend('%N')
               tfr.read_line
            end
            Result.append(tfr.last_string)
            tfr.disconnect
         end
      end

end -- class ABSTRACT_TEST_WEBCLIENT
