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
expanded class CHANNEL_FACTORY

insert
   TEST_FACADE[CHANNEL_FACTORY_DEF]

feature {CLIENT}
   new_client_channel (tmpdir: ABSTRACT_STRING): CLIENT_CHANNEL
      require
         tmpdir /= Void
      do
         Result := def.new_client_channel(tmpdir)
      ensure
         Result /= Void
      end

feature {SERVER}
   new_server_channel: SERVER_CHANNEL
      do
         Result := def.new_server_channel
      ensure
         Result /= Void
      end

feature {}
   def_impl: CHANNEL_FACTORY_IMPL
      once
         create Result
      end

end -- class CHANNEL_FACTORY
