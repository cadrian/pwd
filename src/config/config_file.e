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
class CONFIG_FILE

create {CONFIGURATION}
   make

feature {ANY}
   filename: FIXED_STRING

feature {ANY}
   has (section, key: ABSTRACT_STRING): BOOLEAN
      require
         section /= Void
         key /= Void
      do
         Result := get_no_eval(section, key) /= Void
      end

   get (section, key: ABSTRACT_STRING): FIXED_STRING
      require
         section /= Void
         key /= Void
      do
         Result := eval(get_no_eval(section, key))
      end

   get_no_eval (section, key: ABSTRACT_STRING): FIXED_STRING
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

feature {ANY}
   set (section, key, value: ABSTRACT_STRING)
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
         get_no_eval(section, key) = value.intern
      end

feature {}
   conf: HASHED_DICTIONARY[HASHED_DICTIONARY[FIXED_STRING, FIXED_STRING], FIXED_STRING]

   make (a_filename: like filename; tfr: INPUT_STREAM)
      require
         a_filename /= Void
         tfr /= Void implies tfr.is_connected
      do
         create conf.make
         filename := a_filename
         if tfr /= Void then
            do_parse_conf(tfr)
         end
      ensure
         filename = a_filename
      end

   do_parse_conf (tfr: INPUT_STREAM)
      require
         tfr.is_connected
      local
         section: FIXED_STRING
      do
         from
            tfr.read_line
         until
            tfr.end_of_input
         loop
            section := add_conf(tfr.last_string, section)
            tfr.read_line
         end
         section := add_conf(tfr.last_string, section)
      end

   add_conf (line: STRING; section: FIXED_STRING): FIXED_STRING
         -- returns the current section
      local
         key, value: FIXED_STRING
      do
         line.left_adjust
         line.right_adjust
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

   decode_config (group_name, line: STRING): FIXED_STRING
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

   config_decoder: REGULAR_EXPRESSION
      local
         builder: REGULAR_EXPRESSION_BUILDER
      once
         Result := builder.convert_python_pattern("^(?P<key>[a-zA-Z0-9_.]+)\s*[:=]\s*(?P<value>.*)$")
      end

   eval (string: ABSTRACT_STRING): FIXED_STRING
         -- takes care of environment variables etc.
      local
         buffer: STRING; i, j: INTEGER; args: COLLECTION[STRING]; arg: STRING; c: CHARACTER; processor: PROCESSOR
      do
         if string /= Void then
            buffer := once ""
            buffer.clear_count
            args := processor.split_arguments(string)
            from
               i := args.lower
            until
               i > args.upper
            loop
               arg := args.item(i)
               if not arg.is_empty then
                  if i > args.lower then
                     buffer.extend(' ')
                  end
                  if arg.valid_index(arg.first_index_of(' ')) then
                     buffer.extend('"')
                     from
                        j := arg.lower
                     until
                        j > arg.upper
                     loop
                        c := arg.item(j)
                        if c = '"' or else c = '\' then
                           buffer.extend('\')
                        end

                        buffer.extend(c)
                        j := j + 1
                     end

                     buffer.extend('"')
                  else
                     buffer.append(arg)
                  end
               end

               i := i + 1
            end

            Result := buffer.intern
         end
      end

invariant
   conf /= Void
   filename /= Void

end -- class CONFIG_FILE
