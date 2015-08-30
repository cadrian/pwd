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
class PASS_GENERATOR_PARSER

insert
   PASS_GENERATOR_PARSER_CONSTANTS

create {PASS_GENERATOR}
   parse

feature {PASS_GENERATOR}
   recipe: FAST_ARRAY[PASS_GENERATOR_MIX]

   total_quantity: INTEGER

   parsed: BOOLEAN

feature {}
   last_quantity: INTEGER

   last_ingredient: STRING

   index: INTEGER

   source: FIXED_STRING

   parse (a_source: ABSTRACT_STRING)
      require
         a_source /= Void
      do
         create recipe.with_capacity(4)
         total_quantity := 0
         source := a_source.intern
         index := a_source.lower
         parsed := parse_recipe
      end

   parse_recipe: BOOLEAN
      require
         source.valid_index(index)
      do
         from
            Result := True
         until
            not Result or else not source.valid_index(index)
         loop
            Result := parse_mix
         end
      end

   parse_mix: BOOLEAN
      require
         source.valid_index(index)
      do
         if parse_quantity and then parse_ingredient then
            recipe.add_last(create {PASS_GENERATOR_MIX}.make(last_quantity, last_ingredient.intern))
            total_quantity := total_quantity + last_quantity
            Result := True
         end
      end

   parse_quantity: BOOLEAN
      require
         source.valid_index(index)
      do
         from
            last_quantity := 0
         until
            not source.valid_index(index) or else not source.item(index).is_digit
         loop
            last_quantity := last_quantity * 10 + source.item(index).value
            index := index + 1
         end
         if last_quantity = 0 then
            last_quantity := 1
         end

         Result := source.valid_index(index)
      end

   parse_ingredient: BOOLEAN
      require
         source.valid_index(index)
      do
         from
            Result := True
            last_ingredient := once ""
            last_ingredient.clear_count
         until
            not Result or else not source.valid_index(index) or else source.item(index) = '+'
         loop
            inspect
               source.item(index)
            when 'a' then
               last_ingredient.append(letters)
            when 'n' then
               last_ingredient.append(figures)
            when 's' then
               last_ingredient.append(symbols)
            else
               Result := False
            end
            index := index + 1
         end
         if Result and then source.valid_index(index) then
            index := index + 1
         end
      end

invariant
   parsed implies not recipe.is_empty
   parsed implies total_quantity > 0

end -- class PASS_GENERATOR_PARSER
