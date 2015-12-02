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
class JSON_FILE_CODEC

inherit
   JSON_CODEC[DICTIONARY[KEY, FIXED_STRING]]

insert
   KEY_HANDLER
   LOGGING

create {ANY}
   make

feature {ANY}
   error_message: ABSTRACT_STRING

feature {JSON_HANDLER}
   build (data: DICTIONARY[KEY, FIXED_STRING]): JSON_TEXT
      local
         keys: LINKED_HASHED_DICTIONARY[JSON_VALUE, JSON_STRING]
      do
         create keys.make
         data.for_each(agent add_key(keys, ?))
         create {JSON_OBJECT} Result.make(keys)
      end

   on_error (message: ABSTRACT_STRING; line, column: INTEGER)
      local
         msg: ABSTRACT_STRING
      do
         msg := once "#(1):#(2):#(3)" # &line # &column # message
         if error_message = Void then
            error_message := msg
         else
            error_message := "#(1)%N#(2)" # error_message # msg
         end
      end

   create_array: JSON_DATA
      do
         log.warning.put_line(once "unexpected array")
      end

   add_to_array (array, value: JSON_DATA)
      do
         crash
      end

   finalize_array (array: JSON_DATA)
      do
         crash
      end

   create_object: JSON_DATA
      local
         empty_key: TUPLE[FIXED_STRING, STRING, INTEGER, INTEGER, HASHED_DICTIONARY[ABSTRACT_STRING, FIXED_STRING]]
      do
         inspect
            depth
         when 0 then
            create {VAULT_DATA[DICTIONARY[KEY, FIXED_STRING]]} Result.make(create {LINKED_HASHED_DICTIONARY[KEY, FIXED_STRING]}.make)
         when 1 then
            create empty_key
            create {VAULT_DATA[TUPLE[FIXED_STRING, STRING, INTEGER, INTEGER, HASHED_DICTIONARY[ABSTRACT_STRING, FIXED_STRING]]]} Result.make(empty_key)
         when 2 then
            create {VAULT_DATA[HASHED_DICTIONARY[ABSTRACT_STRING, FIXED_STRING]]} Result.make(create {HASHED_DICTIONARY[ABSTRACT_STRING, FIXED_STRING]}.make)
         else
            crash -- not supported
         end
         depth := depth + 1
      end

   add_to_object (a_object, a_key, a_value: JSON_DATA)
      local
         keys: VAULT_DATA[DICTIONARY[KEY, FIXED_STRING]]
         key: VAULT_DATA[TUPLE[FIXED_STRING, STRING, INTEGER, INTEGER, HASHED_DICTIONARY[ABSTRACT_STRING, FIXED_STRING]]]
         properties: VAULT_DATA[HASHED_DICTIONARY[ABSTRACT_STRING, FIXED_STRING]]
         k, vs: VAULT_DATA[STRING]
         vi: VAULT_DATA[INTEGER]
         new_key: KEY
         bzero: BZERO
      do
         check
            depth > 0
         end
         inspect
            depth
         when 1 then
            keys ::= a_object
            k ::= a_key
            key ::= a_value
            create new_key.from_file(key.item.first, key.item.second, key.item.third, key.item.fourth, key.item.fifth)
            keys.item.add(new_key, k.item.intern)
         when 2 then
            key ::= a_object
            k ::= a_key
            inspect
               k.item
            when "name" then
               vs ::= a_value
               key.item.set_first(vs.item.intern)
            when "pass" then
               vs ::= a_value
               key.item.set_second(vs.item.twin)
               bzero(vs.item)
            when "add_count" then
               vi ::= a_value
               key.item.set_third(vi.item)
            when "del_count" then
               vi ::= a_value
               key.item.set_fourth(vi.item)
            when "properties" then
               properties ::= a_value
               key.item.set_fifth(properties.item)
            else
               log.warning.put_line(once "unexpected key entry: %"#(1)%"" # k.item)
            end
         when 3 then
            properties ::= a_object
            k ::= a_key
            inspect
               k.item
            when "username", "url", "tags" then
               vs ::= a_value
               properties.item.put(vs.item, k.item.intern)
            else
               log.warning.put_line(once "unexpected property: %"#(1)%"" # k.item)
            end
         else
            log.warning.put_line(once "unexpected object at depth #(1)" # &depth)
         end
      end

   finalize_object (object: JSON_DATA)
      do
         depth := depth - 1
      end

   create_string (string: JSON_STRING): JSON_DATA
      local
         bzero: BZERO; s: STRING
      do
         s := string.string.as_utf8
         create {VAULT_DATA[STRING]} Result.make(s.twin)
         bzero(s)
      end

   create_number (number: JSON_NUMBER): JSON_DATA
      do
         create {VAULT_DATA[INTEGER]} Result.make(number.to_integer.to_integer_32)
      end

   true_value: JSON_DATA
      do
         log.warning.put_line(once "unexpected true")
      end

   false_value: JSON_DATA
      do
         log.warning.put_line(once "unexpected false")
      end

   null_value: JSON_DATA
      do
         log.warning.put_line(once "unexpected null")
      end

   depth: INTEGER

feature {}
   make
      do
      end

   add_key (keys: DICTIONARY[JSON_VALUE, JSON_STRING]; key: KEY)
      local
         name, pass: JSON_STRING
         add_count, del_count: JSON_NUMBER
         n64_zero: NATURAL_64
         i64_zero: INTEGER_64
         props: HASHED_DICTIONARY[JSON_VALUE, JSON_STRING]; properties: JSON_OBJECT
         tags: STRING
      do
         create name.from_string(key.name)
         create pass.from_string(key.pass)
         create add_count.make(1, key.add_count.to_natural_64, n64_zero, i64_zero, i64_zero)
         create del_count.make(1, key.del_count.to_natural_64, n64_zero, i64_zero, i64_zero)
         create props.make
         if key.username /= Void then
            props.add(create {JSON_STRING}.from_string(key.username), Property_username)
         end
         if key.url /= Void then
            props.add(create {JSON_STRING}.from_string(key.url), Property_url)
         end
         if not key.tags.is_empty then
            props.add(create {JSON_STRING}.from_string(key.username), Property_username)
            tags := ""
            key.tags.for_each(agent (tag: FIXED_STRING; tagstring: STRING)
                                 do
                                    if not tagstring.is_empty then
                                       tagstring.extend(' ')
                                    end
                                    tagstring.append(tag)
                                 end (?, tags))
            props.add(create {JSON_STRING}.from_string(tags), Property_tags)
         end
         create properties.make(props)
         keys.add(create {JSON_OBJECT}.make({LINKED_HASHED_DICTIONARY[JSON_VALUE, JSON_STRING] <<
                                               name, Key_name;
                                               pass, Key_pass;
                                               add_count, Key_add_count;
                                               del_count, Key_del_count;
                                               properties, Key_properties
                                            >> }),
                  name)
      end

   Key_name: JSON_STRING
      once
         create Result.from_string("name")
      end

   Key_pass: JSON_STRING
      once
         create Result.from_string("pass")
      end

   Key_add_count: JSON_STRING
      once
         create Result.from_string("add_count")
      end

   Key_del_count: JSON_STRING
      once
         create Result.from_string("del_count")
      end

   Key_properties: JSON_STRING
      once
         create Result.from_string("properties")
      end

   Property_username: JSON_STRING
      once
         create Result.from_string("username")
      end

   Property_url: JSON_STRING
      once
         create Result.from_string("url")
      end

   Property_tags: JSON_STRING
      once
         create Result.from_string("tags")
      end

end -- class JSON_FILE_CODEC
