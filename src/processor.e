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
expanded class PROCESSOR

feature {ANY}
   execute (command: STRING; arguments: ABSTRACT_STRING): PROCESS is
      require
         command /= Void
      do
         Result := execute_(command, arguments, True)
      ensure
         Result /= Void
      end

   execute_redirect (command: STRING; arguments: ABSTRACT_STRING): PROCESS is
      require
         command /= Void
      do
         Result := execute_(command, arguments, False)
      ensure
         Result /= Void
      end

   fork: PROCESS is
      local
         factory: PROCESS_FACTORY
      do
         factory.set_direct_input(True)
         factory.set_direct_output(True)
         factory.set_direct_error(True)
         Result := factory.create_process
         Result.duplicate
      end

feature {}
   execute_ (command: STRING; arguments: ABSTRACT_STRING; output: BOOLEAN): PROCESS is
      require
         command /= Void
      local
         factory: PROCESS_FACTORY
         args: FAST_ARRAY[STRING]
      do
         if arguments /= Void then
            args := parse_arguments(arguments.intern)
         end
         factory.set_direct_output(output)
         factory.set_direct_error(output)
         Result := factory.execute(command, args)
      ensure
         Result /= Void
      end

   arguments_map: HASHED_DICTIONARY[FAST_ARRAY[STRING], FIXED_STRING] is
      once
         create Result.make
      end

   parse_arguments (arguments: FIXED_STRING): FAST_ARRAY[STRING] is
      do
         Result := arguments_map.fast_reference_at(arguments)
         if Result = Void then
            Result := a_arguments(arguments)
            arguments_map.add(Result, arguments)
         end
      end

   a_arguments (arguments: FIXED_STRING): FAST_ARRAY[STRING] is
      local
         i, state: INTEGER; c: CHARACTER; word: STRING
      do
         create Result.make(0)
         word := once ""
         word.clear_count
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
               inspect
                  c
               when '%'' then
                  state := State_word
               when '\' then
                  if i = arguments.upper then
                     state := -1
                  else
                     state := State_escape
                  end
               else
                  word.extend(c)
               end
            when State_simple_quote_escape then
               word.extend(c)
               state := State_simple_quote
            when State_double_quote then
               inspect
                  c
               when '%"' then
                  state := State_word
               when '\' then
                  if i = arguments.upper then
                     state := -1
                  else
                     state := State_escape
                  end
               else
                  word.extend(c)
               end
            when State_double_quote_escape then
               word.extend(c)
               state := State_double_quote
            end
            i := i + 1
         end
         if state < 0 then
            std_error.put_line(once "Syntax error while parsing arguments:%N#(1)" # arguments)
            die_with_code(1)
         else
            Result.add_last(word)
         end
      ensure
         Result /= Void
      end

   State_blank: INTEGER is 0
   State_word: INTEGER is 1
   State_escape: INTEGER is 2
   State_simple_quote: INTEGER is 11
   State_simple_quote_escape: INTEGER is 12
   State_double_quote: INTEGER is 21
   State_double_quote_escape: INTEGER is 22

end
