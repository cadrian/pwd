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
class PROCESSOR_IMPL

inherit
   PROCESSOR_DEF

insert
   LOGGING

feature {PROCESSOR}
   execute (command, arguments: ABSTRACT_STRING): PROCESS
      do
         Result := execute_(command, arguments, False, True, True)
      end

   execute_redirect (command, arguments: ABSTRACT_STRING): PROCESS
      do
         Result := execute_(command, arguments, False, False, True)
      end

   execute_to_dev_null (command, arguments: ABSTRACT_STRING): PROCESS
      do
         Result := execute_(command, arguments, False, False, False)
      end

   execute_direct (command, arguments: ABSTRACT_STRING): PROCESS
      do
         Result := execute_(command, arguments, True, True, True)
      end

   fork: PROCESS
      local
         factory: PROCESS_FACTORY
      do
         factory.set_direct_input(True)
         factory.set_direct_output(True)
         factory.set_direct_error(True)
         Result := factory.create_process
         Result.duplicate
      end

   split_arguments (arguments: ABSTRACT_STRING): COLLECTION[STRING]
      do
         Result := parse_arguments(arguments.intern)
      end

   pid: INTEGER
      do
         c_inline_c("[
                     R = getpid();
                     ]")
      end

feature {}
   execute_ (command, arguments: ABSTRACT_STRING; direct_input, direct_output, direct_error: BOOLEAN): PROCESS
      require
         command /= Void
      local
         factory: PROCESS_FACTORY; args: FAST_ARRAY[STRING]
      do
         if arguments /= Void then
            args := parse_arguments(arguments.intern)
         end
         if log.is_trace then
            log.trace.put_string(command)
            if args /= Void then
               args.for_each(agent (s: STRING)
                  do
                     log.trace.put_character(' ')
                     log.trace.put_string(s)
                  end(?))
            end

            log.trace.put_new_line
         end

         factory.set_direct_input(direct_input)
         factory.set_direct_output(direct_output)
         factory.set_direct_error(direct_error)
         Result := factory.execute(command.out, args)
      ensure
         Result /= Void
      end

   arguments_map: HASHED_DICTIONARY[FAST_ARRAY[STRING], FIXED_STRING]
      once
         create Result.make
      end

   parse_arguments (arguments: FIXED_STRING): FAST_ARRAY[STRING]
      do
         Result := arguments_map.fast_reference_at(arguments)
         if Result = Void then
            Result := a_arguments(arguments)
            arguments_map.add(Result, arguments)
         end
      end

   a_arguments (arguments: FIXED_STRING): FAST_ARRAY[STRING]
      local
         i, state: INTEGER; c: CHARACTER; word, var: STRING
      do
         create Result.make(0)
         word := once ""
         word.clear_count
         var := once ""
         var.clear_count

         from
            i := arguments.lower
         until
            state < 0 or else i > arguments.upper
         loop
            c := arguments.item(i)
            inspect
               state
            when State_blank then
               if not c.is_separator then
                  inspect
                     c
                  when '#' then
                     i := arguments.upper
                  when '%'' then
                     state := State_simple_quote
                  when '%"' then
                     state := State_double_quote
                  when '$' then
                     state := State_simple_variable
                  when '\' then
                     if i = arguments.upper then
                        state := -1
                     else
                        state := State_escape
                     end
                  else
                     state := State_word
                     word.extend(c)
                  end
               end
            when State_word then
               inspect
                  c
               when '#' then
                  i := arguments.upper
               when '%'' then
                  state := State_simple_quote
               when '%"' then
                  state := State_double_quote
               when '$' then
                  state := State_simple_variable
               when '\' then
                  if i = arguments.upper then
                     state := -1
                  else
                     state := State_escape
                  end
               else
                  if c.is_separator then
                     Result.add_last(word.twin)
                     word.clear_count
                     state := State_blank
                  else
                     word.extend(c)
                  end
               end
            when State_escape then
               word.extend(c)
               state := State_word
            when State_simple_quote then
               if i = arguments.upper and then c /= '%'' then
                  state := -1
               else
                  inspect
                     c
                  when '%'' then
                     state := State_word
                  when '\' then
                     state := State_simple_quote_escape
                  else
                     word.extend(c)
                  end
               end
            when State_simple_quote_escape then
               word.extend(c)
               state := State_simple_quote
            when State_double_quote then
               if i = arguments.upper and then c /= '%"' then
                  state := -1
               else
                  inspect
                     c
                  when '%"' then
                     state := State_word
                  when '$' then
                     var.clear_count
                     state := State_simple_variable_quoted
                  when '\' then
                     state := State_double_quote_escape
                  else
                     word.extend(c)
                  end
               end
            when State_double_quote_escape then
               word.extend(c)
               state := State_double_quote
            when State_simple_variable, State_simple_variable_quoted then
               if var.is_empty and then c = '{' then
                  if state = State_simple_variable then
                     state := State_braced_variable
                  else
                     state := State_braced_variable_quoted
                  end
               else
                  inspect
                     c
                  when 'A' .. 'Z', 'a' .. 'z', '_' then
                     var.extend(c)
                  else
                     append_var(word, var)
                     var.clear_count
                     i := i - 1
                     if state = State_simple_variable then
                        state := State_word
                     else
                        state := State_double_quote
                     end
                  end
               end
            when State_braced_variable, State_braced_variable_quoted then
               if i = arguments.upper then
                  state := -1
               elseif c = '}' then
                  if state = State_braced_variable then
                     state := State_word
                  else
                     state := State_double_quote
                  end
                  append_var(word, var)
                  var.clear_count
               else
                  var.extend(c)
               end
            end
            i := i + 1
         end

         if state < 0 then
            std_error.put_line("Syntax error while parsing arguments:%N#(1)" # arguments)
            die_with_code(1)
         else
            if not var.is_empty then
               append_var(word, var)
            end
            Result.add_last(word.twin)
         end
      ensure
         Result /= Void
      end

   append_var (word, var: STRING)
      require
         word /= Void
         var /= Void
      local
         value: STRING
      do
         value := environment.variable(var)
         word.append(value)
      end

   State_blank: INTEGER 0

   State_word: INTEGER 1

   State_escape: INTEGER 2

   State_simple_quote: INTEGER 11

   State_simple_quote_escape: INTEGER 12

   State_double_quote: INTEGER 21

   State_double_quote_escape: INTEGER 22

   State_simple_variable: INTEGER 31

   State_braced_variable: INTEGER 32

   State_simple_variable_quoted: INTEGER 33

   State_braced_variable_quoted: INTEGER 34

   environment: ENVIRONMENT

end -- class PROCESSOR_IMPL
