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
      do
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
            mock_channel_factory.new_client_channel(tmpdir).then_return(mock_client_channel.mock),
--            mock_channel_factory.new_server_channel.then_return(mock_server_channel.mock)
         >>})

         -- Mock expectations for channels start, server start...
         scenario.expect({FAST_ARRAY[MOCK_EXPECTATION] <<

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
                                    end(?))

            mock_client_channel.cleanup

         >>})

         scenario.replay_all
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

feature {}
   client: WEBCLIENT

   call_cgi (method, path: STRING): STRING
      local
         system: SYSTEM; cgi: CGI_IO
         sos: STRING_OUTPUT_STREAM
      do
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
