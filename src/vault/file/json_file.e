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
class JSON_FILE
   --
   -- JSON vault file structure
   --

inherit
   VAULT_FILE

insert
   JSON_HANDLER
   LOGGING

feature {ANY}
   load (keys: DICTIONARY[KEY, FIXED_STRING]; vault_io: VAULT_IO): ABSTRACT_STRING
      do
         Result := vault_io.load(agent on_open(keys, ?))
      end

   save (keys: DICTIONARY[KEY, FIXED_STRING]; vault_io: VAULT_IO): ABSTRACT_STRING
      do
         Result := vault_io.save(agent do_save(keys, ?), agent pass_error(?))
      end

feature {} -- load
   on_open (keys: DICTIONARY[KEY, FIXED_STRING]; vault_file: INPUT_STREAM): ABSTRACT_STRING
      local
         codec: JSON_FILE_CODEC
         k: JSON_TYPED_DATA[DICTIONARY[KEY, FIXED_STRING]]
         value: JSON_VALUE
      do
         create codec.make
         value := codec.parse(vault_file)
         Result := codec.error_message
         if Result = Void or else Result.is_empty then
            k ::= decoder.decode(codec, value)
            k.item.for_each(agent (keymap: DICTIONARY[KEY, FIXED_STRING]; key: KEY) do keymap.add(key, key.name) end (keys, ?))
            Result := once ""
         end
         if value /= Void then
            value.accept(create {JSON_CLEANER})
         end
      end

   decoder: JSON_DECODER
      once
         create Result.make
      end

feature {} -- save
   do_save (keys: DICTIONARY[KEY, FIXED_STRING]; stream: OUTPUT_STREAM): ABSTRACT_STRING
      local
         codec: JSON_FILE_CODEC
         value: JSON_VALUE
      do
         create codec.make
         value := codec.build(keys)
         Result := codec.error_message
         if Result = Void then
            encoder.encode_in(value, stream)
            Result := once ""
         end
         if value /= Void then
            value.accept(create {JSON_CLEANER})
         end
      end

   pass_error (error: ABSTRACT_STRING): ABSTRACT_STRING then error end

   encoder: JSON_ENCODER
      once
         create Result.make
      end

end -- class JSON_FILE
