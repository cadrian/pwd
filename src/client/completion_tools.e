-- This file is part of pwdmgr.
-- Copyright (C) 2012-2014 Cyril Adrian <cyril.adrian@gmail.com>
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
expanded class COMPLETION_TOOLS

feature {}
   no_completion: TRAVERSABLE[FIXED_STRING]
      once
         create {FAST_ARRAY[FIXED_STRING]} Result.make(0)
      end

   filter_completions (completions: ITERATOR[FIXED_STRING]; word: FIXED_STRING): AVL_SET[FIXED_STRING]
      require
         completions /= Void
         word /= Void
      do
         create Result.make
         completions.for_each(agent (completions_set: AVL_SET[FIXED_STRING]; completion: FIXED_STRING)
            require
               completions_set /= Void
               completion /= Void
            do
               if completion.has_prefix(word) then
                  completions_set.add(completion)
               end
            end(Result, ?))
      end

end -- class COMPLETION_TOOLS
