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
deferred class QUERY_VISITOR

inherit
   VISITOR

feature {QUERY_CLOSE}
   visit_close (query: QUERY_CLOSE) is
      require
         query /= Void
      deferred
      end

feature {QUERY_GET}
   visit_get (query: QUERY_GET) is
      require
         query /= Void
      deferred
      end

feature {QUERY_LIST}
   visit_list (query: QUERY_LIST) is
      require
         query /= Void
      deferred
      end

feature {QUERY_MASTER}
   visit_master (query: QUERY_MASTER) is
      require
         query /= Void
      deferred
      end

feature {QUERY_MERGE}
   visit_merge (query: QUERY_MERGE) is
      require
         query /= Void
      deferred
      end

feature {QUERY_PING}
   visit_ping (query: QUERY_PING) is
      require
         query /= Void
      deferred
      end

feature {QUERY_SAVE}
   visit_save (query: QUERY_SAVE) is
      require
         query /= Void
      deferred
      end

feature {QUERY_SET}
   visit_set (query: QUERY_SET) is
      require
         query /= Void
      deferred
      end

feature {QUERY_STOP}
   visit_stop (query: QUERY_STOP) is
      require
         query /= Void
      deferred
      end

feature {QUERY_UNSET}
   visit_unset (query: QUERY_UNSET) is
      require
         query /= Void
      deferred
      end

end
