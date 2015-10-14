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
expanded class XDG
   --
   -- freedesktop management
   --

insert
   FILE_TOOLS
   BASIC_DIRECTORY

feature {ANY}
   read_data (filename: ABSTRACT_STRING): TEXT_FILE_READ
      do
         Result := read(filename, data_dirs)
      ensure
         Result /= Void implies Result.is_connected
      end

   read_config (filename: ABSTRACT_STRING): TEXT_FILE_READ
      do
         Result := read(filename, config_dirs)
      ensure
         Result /= Void implies Result.is_connected
      end

   cache_home: FIXED_STRING
      once
         Result := getenv("XDG_CACHE_HOME", Void, agent : ABSTRACT_STRING
            do
               Result := "#(1)/.cache/pwd" # home
            end)
         check_dir(Result)
      end

   runtime_dir: FIXED_STRING
      once
         Result := getenv("XDG_RUNTIME_DIR", Void, agent : ABSTRACT_STRING
            do
               Result := getenv("TMPDIR", agent (tmp: ABSTRACT_STRING): ABSTRACT_STRING
                  do
                     Result := "#(1)/pwd" # tmp
                  end(?), agent : ABSTRACT_STRING
                  do
                     Result := "/tmp/pwd-#(1)" # user
                  end)
            end)
         check_dir(Result)
      end

   data_home: FIXED_STRING
      once
         Result := ("#(1)/pwd" # data_home_).intern
      end

   config_home: FIXED_STRING
      once
         Result := ("#(1)/pwd" # config_home_).intern
      end

feature {}
   read (filename: ABSTRACT_STRING; dirs: TRAVERSABLE[FIXED_STRING]): TEXT_FILE_READ
      local
         i: INTEGER; path: ABSTRACT_STRING
      do
         from
            i := dirs.lower
         until
            Result /= Void or else i > dirs.upper
         loop
            path := once "#(1)/pwd/#(2)" # dirs.item(i) # filename
            if file_exists(path) then
               debug
                  std_error.put_line("Reading config from #(1)" # path)
               end
               create Result.connect_to(path)
            end

            i := i + 1
         end
      ensure
         Result /= Void implies Result.is_connected
      end

   data_home_: FIXED_STRING
      once
         Result := getenv("XDG_DATA_HOME", Void, agent : ABSTRACT_STRING
            do
               Result := "#(1)/.local/share" # home
            end)
      end

   config_home_: FIXED_STRING
      once
         Result := getenv("XDG_CONFIG_HOME", Void, agent : ABSTRACT_STRING
            do
               Result := "#(1)/.config" # home
            end)
      end

   home: FIXED_STRING
      once
         Result := getenv("HOME", Void, Void)
      end

   user: FIXED_STRING
      once
         Result := getenv("USER", Void, Void)
      end

feature {}
   data_dirs: TRAVERSABLE[FIXED_STRING]
      local
         value: FIXED_STRING; dirs: FAST_ARRAY[FIXED_STRING]
      once
         create dirs.with_capacity(4)
         dirs.add_last(data_home_)
         value := getenv("XDG_DATA_DIRS", Void, agent : ABSTRACT_STRING
            do
               Result := "/usr/local/share/:/usr/share/"
            end)
         split_dirs(value, dirs)
         Result := dirs
      end

   config_dirs: TRAVERSABLE[FIXED_STRING]
      local
         value: FIXED_STRING; dirs: FAST_ARRAY[FIXED_STRING]
      once
         create dirs.with_capacity(4)
         dirs.add_last(config_home_)
         value := getenv("XDG_CONFIG_DIRS", Void, agent : ABSTRACT_STRING
            do
               Result := "/usr/local/etc:/etc/xdg"
            end) -- the first one is not standard but useful for local installs
         split_dirs(value, dirs)
         Result := dirs
      end

   check_dir (dir: FIXED_STRING)
      require
         dir /= Void
      do
         if not is_directory(dir) then
            if not create_new_directory(dir) then
               std_error.put_line("**** Fatal error: could not create #(1)" # dir)
               die_with_code(1)
            end
         end
      end

feature {}
   system: SYSTEM

   split_dirs (value: FIXED_STRING; dirs: FAST_ARRAY[FIXED_STRING])
      require
         value /= Void
         dirs /= Void
      local
         start, next: INTEGER
      do
         from
            start := value.lower
            next := start
         until
            not value.valid_index(next)
         loop
            next := value.index_of(':', start)
            if value.valid_index(next) then
               dirs.add_last(value.substring(start, next - 1))
               start := next + 1
            else
               dirs.add_last(value.substring(start, value.upper))
            end
         end
      end

   getenv (var: ABSTRACT_STRING; ext: FUNCTION[TUPLE[ABSTRACT_STRING], ABSTRACT_STRING]
      def: FUNCTION[TUPLE, ABSTRACT_STRING]): FIXED_STRING
      require
         var /= Void
      local
         value: STRING
      do
         value := system.get_environment_variable(var.out)
         if value = Void or else value.is_empty then
            if def = Void then
               -- mandatory
               std_error.put_line("**** Fatal error: no $#(1) defined!" # var)
               die_with_code(1)
            end
            Result := def.item([]).intern
         else
            if ext = Void then
               Result := value.intern
            else
               Result := ext.item([value]).intern
            end
         end
      ensure
         Result /= Void
      end

end -- class XDG
