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
expanded class COMPLETION_TOOLS

feature {}
   no_completion: TRAVERSABLE[FIXED_STRING] is
      once
         create {FAST_ARRAY[FIXED_STRING]} Result.make(0)
      end

   filter_completions (completions: ITERATOR[FIXED_STRING]; word: FIXED_STRING): AVL_SET[FIXED_STRING] is
      require
         completions /= Void
         word /= Void
      do
         create Result.make
         completions.do_all(agent (completions: AVL_SET[FIXED_STRING]; word, completion: FIXED_STRING) is
                            require
                               completions /= Void
                               word /= Void
                               completion /= Void
                            do
                               if completion.has_prefix(word) then
                                  completions.add(completion)
                               end
                            end (Result, word, ?))
      end

end
