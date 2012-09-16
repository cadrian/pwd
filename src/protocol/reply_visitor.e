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
deferred class REPLY_VISITOR

inherit
   VISITOR

feature {REPLY_CLOSE}
   visit_close (reply: REPLY_CLOSE) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_GET}
   visit_get (reply: REPLY_GET) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_IS_OPEN}
   visit_is_open (reply: REPLY_IS_OPEN) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_LIST}
   visit_list (reply: REPLY_LIST) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_MASTER}
   visit_master (reply: REPLY_MASTER) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_MERGE}
   visit_merge (reply: REPLY_MERGE) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_PING}
   visit_ping (reply: REPLY_PING) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_SAVE}
   visit_save (reply: REPLY_SAVE) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_SET}
   visit_set (reply: REPLY_SET) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_STOP}
   visit_stop (reply: REPLY_STOP) is
      require
         reply /= Void
      deferred
      end

feature {REPLY_UNSET}
   visit_unset (reply: REPLY_UNSET) is
      require
         reply /= Void
      deferred
      end

end
