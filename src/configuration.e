-- This file is part of pwdmgr.
--
-- pwdmgr is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, version 3 of the License.
--
-- pwdmgr is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with pwdmgr.  If not, see <http://www.gnu.org/licenses/>.
--
expanded class CONFIGURATION

insert
   ARGUMENTS
      redefine
         default_create
      end

feature {ANY}
   get (section, key: ABSTRACT_STRING): FIXED_STRING is
      require
         section /= Void
         key /= Void
      local
         section_conf: HASHED_DICTIONARY[FIXED_STRING, FIXED_STRING]
      do
         section_conf := conf.reference_at(section.intern)
         if section_conf /= Void then
            Result := section_conf.reference_at(key.intern)
         end
      end

   filename: FIXED_STRING is
      do
         Result := filename_ref.item
      end

feature {}
   set (section, key, value: ABSTRACT_STRING) is
      require
         not section.is_empty
         not key.is_empty
         not value.is_empty
      local
         section_conf: HASHED_DICTIONARY[FIXED_STRING, FIXED_STRING]
      do
         section_conf := conf.fast_reference_at(section.intern)
         if section_conf = Void then
            create section_conf.make
            conf.add(section_conf, section.intern)
         end
         section_conf.fast_put(value.intern, key.intern)
      ensure
         get(section, key) = value.intern
      end

feature {ANY}
   parse_extra_conf (a_conf_file: ABSTRACT_STRING) is
      require
         a_conf_file /= Void
      local
         tfr: TEXT_FILE_READ
      do
         if filename = Void then
            create tfr.connect_to(a_conf_file.out)
            if tfr.is_connected then
               filename_ref.set_item(a_conf_file.intern)
               do_parse_conf(tfr)
               tfr.disconnect
            end
         end
      end

feature {}
   default_create is
      do
         parse_conf
      end

   available_file_locations: FAST_ARRAY[FIXED_STRING] is
      local
         sys: SYSTEM
      once
         Result := {FAST_ARRAY[FIXED_STRING] <<
                                               ("#(1)/.pwdmgr/config.rc" # sys.get_environment_variable("HOME")).intern,
                                               "/usr/local/etc/pwdmgr.rc".intern,
                                               "/etc/pwdmgr.rc".intern
                                             >> }
      end

   parse_conf is
      local
         tfr: TEXT_FILE_READ; i: INTEGER
      once
         from
            create tfr.make
            i := available_file_locations.lower
         until
            tfr.is_connected or else i > available_file_locations.upper
         loop
            filename_ref.set_item(available_file_locations.item(i))
            tfr.connect_to(filename)
            i := i + 1
         end
         if tfr.is_connected then
            do_parse_conf(tfr)
            tfr.disconnect
         else
            filename_ref.set_item(Void)
         end
      end

   do_parse_conf (tfr: TEXT_FILE_READ) is
      require
         tfr.is_connected
         filename /= Void
      local
         section: FIXED_STRING
      do
         from
            io.put_line(once "Reading conf: #(1)" # filename)
            tfr.read_line
         until
            tfr.end_of_input
         loop
            section := add_conf(tfr.last_string, section)
            tfr.read_line
         end
         section := add_conf(tfr.last_string, section)
      end

   add_conf (line: STRING; section: FIXED_STRING): FIXED_STRING is
         -- returns the current section
      local
         key, value: FIXED_STRING
      do
         Result := section
         if line.is_empty then
            -- ignore
         else
            inspect
               line.first
            when '*', '#', ';' then
               -- ignore comment
            when '[' then
               if line.count <= 2 or else line.last /= ']' then
                  std_error.put_line(once "Invalid configuration line (invalid section):%N#(1)" # line)
               else
                  Result := line.substring(line.lower + 1, line.upper - 1).intern
                  check
                     not Result.is_empty
                  end
               end
            else
               if section = Void then
                  std_error.put_line(once "Invalid configuration line (no section):%N#(1)" # line)
                  die_with_code(1)
               end

               if not config_decoder.match(line) then
                  std_error.put_line(once "Invalid configuration line (incorrect syntax):%N#(1)" # line)
                  die_with_code(1)
               end

               key := decode_config(once "key", line)
               check
                  by_construction_of_regexp: not key.is_empty
               end
               if get(section, key) /= Void then
                  std_error.put_line(once "Duplicate key: #(1) in section [#(2)]" # key # section)
                  die_with_code(1)
               end

               value := decode_config(once "value", line)

               if not value.is_empty then
                  set(section, key, value)
               end
            end
         end
      end

   decode_config (group_name, line: STRING): FIXED_STRING is
      require
         config_decoder.match(line)
      local
         s: STRING
      do
         s := once ""
         s.clear_count
         config_decoder.append_named_group(line, s, group_name)
         Result := s.intern
      end

   config_decoder: REGULAR_EXPRESSION is
      local
         builder: REGULAR_EXPRESSION_BUILDER
      once
         Result := builder.convert_python_pattern("^(?P<key>[a-zA-Z0-9_.]+)\s*[:=]\s*(?P<value>.*)$")
      end

   conf: HASHED_DICTIONARY[HASHED_DICTIONARY[FIXED_STRING, FIXED_STRING], FIXED_STRING] is
      once
         create Result.make
      ensure
         Result /= Void
      end

   filename_ref: REFERENCE[FIXED_STRING] is
      once
         create Result
      end

end
