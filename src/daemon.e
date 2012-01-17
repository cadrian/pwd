class DAEMON

inherit
   JOB
      undefine
         default_create
      end

insert
   PROCESS_FACTORY
   ARGUMENTS
      undefine
         default_create
      end

create {}
   main

feature {LOOP_ITEM}
   prepare (events: EVENTS_SET) is
      local
         t: TIME_EVENTS
      do
         if channel /= Void and then channel.is_connected then
            events.expect(channel.event_can_read)
         else
            events.expect(t.timeout(0))
         end
      end

   is_ready (events: EVENTS_SET): BOOLEAN is
      do
         if events.event_occurred(channel.event_can_read) then
            channel.read_line
            Result := not channel.last_string.is_empty
         end
      end

   continue is
      local
         line: STRING
      do
         line := channel.last_string
         std_output.put_line(once ">>>> #(1)" # line)
         if line.is_equal(once "stop") then
            channel.disconnect
         end
      end

   done: BOOLEAN is
      do
         Result := channel = Void or else not channel.is_connected
      end

   restart is
      do
         create channel.connect_to(file)
      end

feature {}
   file: STRING
   channel: TEXT_FILE_READ

   start is
         -- the main loop
      local
         loop_stack: LOOP_STACK
      do
         create loop_stack.make
         loop_stack.add_job(Current)
         restart
         loop_stack.run
         std_output.put_line("~~~~ DONE ~~~~")
      end

   create_fifo is
      local
         path: POINTER; sts: INTEGER
      do
         c_inline_h("#include <sys/types.h>%N")
         c_inline_h("#include <sys/stat.h>%N")
         c_inline_h("#include <fcntl.h>%N")
         c_inline_h("#include <unistd.h>%N")
         path := file.to_external
         c_inline_c("_sts = mknod((const char*)_path, S_IFIFO | 0600, 0); if (_sts == -1) _sts = errno; if (_sts == EEXIST) _sts = 0;%N")
         if sts /= 0 then
            std_error.put_line(once "#(1): error #(2) while creating #(3)" # command_name # sts.out # file)
            die_with_code(1)
         end
      end

   daemonize is
      local
         proc: PROCESS
      do
         proc := create_process
         proc.duplicate
         if proc.is_child then
            start
         else
            std_output.put_integer(proc.id)
            std_output.put_new_line
            die_with_code(0)
         end
      end

   main is
      do
         if argument_count = 0 then
            std_error.put_line(once "Usage: #(1) <fifo>" # command_name)
            die_with_code(1)
         end
         file := argument(1)
         create_fifo

         default_create
         direct_input := True
         direct_output := True
         direct_error := True

         daemonize
      end

end
