-- This file is part of pwdmgr.
-- Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>
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
expanded class XDG
   --
   -- freedesktop management
   --

insert
   FILE_TOOLS
   BASIC_DIRECTORY

feature {ANY}
   read_data (filename: ABSTRACT_STRING): TEXT_FILE_READ is
      do
         Result := read(filename, data_dirs)
      ensure
         Result /= Void implies Result.is_connected
      end

   read_config (filename: ABSTRACT_STRING): TEXT_FILE_READ is
      do
         Result := read(filename, config_dirs)
      ensure
         Result /= Void implies Result.is_connected
      end

   cache_home: FIXED_STRING is
      once
         Result := getenv("XDG_CACHE_HOME", "#(1)/.cache/pwdmgr" # home)
         check_dir(Result)
      end

   runtime_dir: FIXED_STRING is
      once
         Result := getenv("XDG_RUNTIME_DIR", "/tmp/pwdmgr-#(1)" # user)
         check_dir(Result)
      end

   data_home: FIXED_STRING is
      once
         Result := ("#(1)/pwdmgr" # data_home_).intern
      end

   config_home: FIXED_STRING is
      once
         Result := ("#(1)/pwdmgr" # config_home_).intern
      end

feature {}
   read (filename: ABSTRACT_STRING; dirs: TRAVERSABLE[FIXED_STRING]): TEXT_FILE_READ is
      local
         i: INTEGER; path: ABSTRACT_STRING
      do
         from
            i := dirs.lower
         until
            Result /= Void or else i > dirs.upper
         loop
            path := once "#(1)/pwdmgr/#(2)" # dirs.item(i) # filename
            if file_exists(path) then
               create Result.connect_to(path)
            end
            i := i + 1
         end
      ensure
         Result /= Void implies Result.is_connected
      end

   data_home_: FIXED_STRING is
      once
         Result := getenv("XDG_DATA_HOME", "#(1)/.local/share" # home)
      end

   config_home_: FIXED_STRING is
      once
         Result := getenv("XDG_CONFIG_HOME", "#(1)/.config" # home)
      end

   home: FIXED_STRING is
      once
         Result := getenv("HOME", Void)
      end

   user: FIXED_STRING is
      once
         Result := getenv("USER", Void)
      end

feature {}
   data_dirs: TRAVERSABLE[FIXED_STRING] is
      local
         value: FIXED_STRING; dirs: FAST_ARRAY[FIXED_STRING]
      once
         create dirs.with_capacity(4)
         dirs.add_last(data_home_)
         value := getenv("XDG_DATA_DIRS", "/usr/local/share/:/usr/share/")
         split_dirs(value, dirs)
         Result := dirs
      end

   config_dirs: TRAVERSABLE[FIXED_STRING] is
      local
         value: FIXED_STRING; dirs: FAST_ARRAY[FIXED_STRING]
      once
         create dirs.with_capacity(4)
         dirs.add_last(config_home_)
         value := getenv("XDG_CONFIG_DIRS", "/etc/xdg")
         split_dirs(value, dirs)
         Result := dirs
      end

   check_dir (dir: FIXED_STRING) is
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

   split_dirs (value: FIXED_STRING; dirs: FAST_ARRAY[FIXED_STRING]) is
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

   getenv (var, def: ABSTRACT_STRING): FIXED_STRING is
      require
         var /= Void
         def /= Void implies not def.is_empty
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
            Result := def.intern
         else
            Result := value.intern
         end
      ensure
         Result /= Void
      end

end
