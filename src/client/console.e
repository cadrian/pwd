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
class CONSOLE

inherit
   CLIENT
      redefine
         make
      end

create {}
   make

feature {} -- the CLIENT interface
   stop: BOOLEAN

   run is
      do
         fill_remote_map

         from
            stop := False
            io.put_string(once "[
                                [1;32mWelcome to the pwdmgr administration console![0m

                                [32mpwdmgr Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>
                                This program comes with ABSOLUTELY NO WARRANTY; for details type [33mshow w[32m.
                                This is free software, and you are welcome to redistribute it
                                under certain conditions; type [33mshow c[32m for details.[0m

                                Type [33mhelp[0m for details on available options.
                                Just hit [33m<enter>[0m to exit.

                                ]")
         until
            stop
         loop
            read_command
            if command.is_empty then
               stop := True
            else
               run_command
            end
         end
      rescue
         if exceptions.is_signal then
            log.info.put_line(once "Killed by signal #(1), exitting gracefully." # exceptions.signal_number.out)
            cleanup
            io.put_new_line
            die_with_code(0)
         end
      end

feature {} -- command management
   command: RING_ARRAY[STRING] is
      once
         create Result.with_capacity(16, 0)
      end

   read_command is
      do
         command.clear_count
         io.put_string(once "%N[33mReady.[0m%N[1;32m>[0m ")
         io.flush
         io.read_line
         io.last_string.split_in(command)
      end

   run_command is
      require
         not command.is_empty
         channel.is_ready
      local
         cmd: STRING
      do
         cmd := command.first
         command.remove_first
         inspect
            cmd
         when "add" then
            run_add
         when "rem" then
            run_rem
         when "list" then
            run_list
         when "save" then
            run_save
         when "load" then
            run_load
         when "merge" then
            run_merge
         when "master" then
            io.put_line(once "not yet implemented.")
         when "help" then
            run_help
         when "show" then
            run_show
         when "stop" then
            log.info.put_line(once "stopping server.")
            send("stop")
            stop := True
         else
            command.add_first(cmd) -- yes, add it again... it's a ring array so no harm done
            run_get
         end
      ensure
         channel.is_ready
      end

feature {} -- local vault commands
   unknown_key (key: ABSTRACT_STRING) is
      do
         io.put_line(once "[1mUnknown password:[0m #(1)" # key)
      end

   run_get is
      do
         do_get(command.first, agent xclip, agent unknown_key)
      end

   run_add is
         -- add key
      local
         cmd: ABSTRACT_STRING; pass, recipe: STRING
      do
         inspect
            command.count
         when 1 then
            cmd := once "#(1) random #(2)" # command.first # shared.default_recipe
         when 2 then
            inspect
               command.last
            when "generate" then
               cmd := once "#(1) random #(2)" # command.first # shared.default_recipe
            when "prompt" then
               pass := read_password(once "Please enter the new password for #(1)" # command.first, on_cancel)
               if pass /= Void then
                  cmd := once "#(1) given #(2)" # command.first # pass
               end
            else
               io.put_line(once "[1mError:[0m unrecognized argument '#(1)'" # command.last)
            end
         when 3 then
            recipe := command.last
            command.remove_last
            inspect
               command.last
            when "generate" then
               cmd := once "#(1) random #(2)" # command.first # recipe
            else
               io.put_line(once "[1mError:[0m unrecognized argument '#(1)'" # command.last)
            end
         else
            io.put_line(once "[1mError:[0m bad number of arguments")
         end
         if cmd /= Void then
            call_server(once "set", cmd,
                        agent (stream: INPUT_STREAM) is
                           do
                              stream.read_line
                              if not stream.end_of_input then
                                 data.clear_count
                                 stream.last_string.split_in(data)
                                 if data.count = 2 then
                                    xclip(data.last)
                                 else
                                    check data.count = 1 end
                                    xclip(once "")
                                    io.put_line(once "[1mError[0m") -- ???
                                 end
                              end
                           end)
            send_save
         end
      end

   run_rem is
         -- remove key
      do
         call_server(once "unset", command.first,
                     agent (stream: INPUT_STREAM) is
                        do
                           stream.read_line
                           if not stream.end_of_input then
                              xclip(once "")
                              io.put_line(once "[1mDone[0m")
                           end
                        end)
         send_save
      end

   run_list is
         -- list known keys
      do
         call_server(once "list", Void,
                     agent (stream: INPUT_STREAM) is
                        local
                           str: STRING_OUTPUT_STREAM
                        do
                           create str.make
                           fifo.splice(stream, str)
                           less(str.to_string)
                        end)
      end

feature {} -- help
   run_help is
      do
         less(once "[
                    [1;32mKnown commands[0m

                    [33madd <key> [how][0m    Add a new password. Needs at least a key.
                                       If [33m[how][0m is "generate" then the password is
                                       randomly generated ([1mdefault[0m).
                                       If [33m[how][0m is "generate" with an extra argument then
                                       the extra argument represents a "recipe" used to generate
                                       the password (*).
                                       If [33m[how][0m is "prompt" then the password is asked.
                                       If the password already exists it is changed.
                                       In all cases the password is stored in the clipboard.

                                       (*) A recipe is a series of "ingredients" separated by a '+'.
                                       Each "ingredient" is an optional quantity (default 1)
                                       followed by a series of 'a' (alphanumeric), 'n' (numeric),
                                       or 's' (symbol).
                                       The password is generated using the recipe to randomly select
                                       characters, and mixing them.

                    [33mrem <key>[0m          Removes the password corresponding to the given key.

                    [33mlist[0m               List the known passwords (show only the keys).

                    [33msave [remote][0m      Save the password vault upto the server.
                                       [33m[remote][0m: see note below

                    [33mload [remote][0m      [1mReplace[0m the local vault with the server's version.
                                       Note: in that case you will be asked for the new vault
                                       password (the previous vault is closed).
                                       [33m[remote][0m: see note below

                    [33mmerge [remote][0m     Load the server version and compare to the local one.
                                       Keep the most recent keys and save the merged version
                                       back to the server.
                                       [33m[remote][0m: see note below

                                       [33m[remote][0m note:
                                       The [33mload[0m, [33msave[0m, and [33mmerge[0m commands require an extra argument
                                       if there is more than one available remotes; in that case,
                                       the argument is the remote to select.

                                       #(1)

                    [33mmaster[0m             Change the master password.
                                       [1m(not yet implemented)[0m

                    [33mstop[0m               Stop the server and close the administration console.

                    [33mhelp[0m               Show this screen :-)

                    Any other input is understood as a password request using the given key.
                    If that key exists the password is stored in the clipboard.

                    --------
                    [32mpwdmgr Copyright (C) 2012 Cyril Adrian <cyril.adrian@gmail.com>[0m
                    [32mThis program comes with ABSOLUTELY NO WARRANTY; for details type [33mshow w[32m.[0m
                    [32mThis is free software, and you are welcome to redistribute it[0m
                    [32munder certain conditions; type [33mshow c[32m for details.[0m

                    ]" # help_list_remotes)
      end

   run_show is
      do
         if command.is_empty or else command.first.first = 'w' then
            less(once "{

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.
                       }")
         elseif command.first.first = 'c' then
            less(once "{
                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS
                       }")
         else
            io.put_line(once "[1mUnknown show command[0m")
         end
      end

feature {} -- remote vault management
   run_save is
         -- save to remote
      local
         remote: REMOTE
      do
         remote := selected_remote
         if remote /= Void then
            std_output.put_line(once "[32mPlease wait...[0m")
            remote.save(shared.vault_file)
         end
      end

   run_load is
         -- load from remote
      local
         remote: REMOTE
      do
         remote := selected_remote
         if remote /= Void then
            -- shut the server down
            send("stop")

            std_output.put_line(once "[32mPlease wait...[0m")
            remote.load(shared.vault_file)

            -- stop the inner command loop
            stop := True
            -- ask the main client loop to start again (will restart the server)
            restart := True
         end
      end

   on_cancel: PROCEDURE[TUPLE] is
      once
         Result := agent is do std_output.put_line(once "[1mCancelled.[0m") end
      end

   run_merge is
         -- merge from remote
      local
         merge_pass0, merge_pass: STRING
         remote: REMOTE
      do
         remote := selected_remote
         if remote /= Void then
            std_output.put_line(once "[32mPlease wait...[0m")
            remote.load(merge_vault)

            merge_pass0 := read_password(once "Please enter the encryption phrase%Nto the remote vault%N(just leave empty if the same as the current vault's)", on_cancel)
            if merge_pass0 = Void then
               -- cancelled
            else
               if merge_pass0.is_empty then
                  merge_pass := master_pass
               else
                  merge_pass := once ""
                  merge_pass.copy(merge_pass0)
               end
               call_server(once "merge", once "#(1) #(2)" # merge_vault # merge_pass,
                           agent (stream: INPUT_STREAM) is
                              do
                                 stream.read_line
                                 if not stream.end_of_input then
                                    xclip(once "")
                                    io.put_line(once "[1mDone[0m")
                                 end
                              end)
               send_save
               remote.save(shared.vault_file)
            end

            delete(merge_vault)
         end
      end

feature {} -- helpers
   merge_vault: FIXED_STRING is
      once
         Result := ("#(1)/merge_vault" # tmpdir).intern
      end

   less (string: ABSTRACT_STRING) is
      local
         proc: PROCESS
      do
         proc := processor.execute(once "less", once "-R")
         if proc.is_connected then
            proc.input.put_string(string)
            proc.input.flush
            proc.input.disconnect
            proc.wait
         end
      end

   remote_map: LINKED_HASHED_DICTIONARY[REMOTE, FIXED_STRING]

   add_remote (section: FIXED_STRING) is
      local
         remote: REMOTE
         remote_factory: REMOTE_FACTORY
      do
         remote := remote_factory.new_remote(section, Current)
         if remote /= Void then
            remote_map.add(remote, section)
         end
      end

   fill_remote_map is
      local
         remote_sections: FIXED_STRING
         start, next: INTEGER
      do
         remote_map.clear_count
         remote_sections := conf(config_remote_sections)
         if remote_sections /= Void then
            from
               start := remote_sections.lower
               next := remote_sections.first_index_of(',')
            until
               not remote_sections.valid_index(next)
            loop
               add_remote(remote_sections.substring(start, next - 1))
               start := next + 1
               next := remote_sections.index_of(',', start)
            end
            add_remote(remote_sections.substring(start, remote_sections.upper))
         end
      end

   list_remotes: STRING is
      local
         i: INTEGER
      do
         Result := once ""
         Result.clear_count
         from
            i := remote_map.lower
         until
            i > remote_map.upper
         loop
            if i > remote_map.lower then
               Result.append(once ", ")
            end
            Result.append(remote_map.key(i))
            i := i + 1
         end
      end

   selected_remote: REMOTE is
      do
         if remote_map.is_empty then
            std_output.put_line(once "[1mNo remote defined![0m")
         else
            if remote_map.count = 1 then
               if not command.is_empty then
                  std_output.put_line(once "[1mRemote argument ignored (only one remote)[0m")
               end
               Result := remote_map.first
            else
               if command.is_empty then
                  std_output.put_line(once "[1mPlease specify the remote to use (#(1))[0m" # list_remotes)
               else
                  if command.count > 1 then
                     std_output.put_line(once "[1mAll arguments but the first one are ignored[0m")
                  end
                  Result := remote_map.reference_at(command.first.intern)
                  if Result = Void then
                     std_output.put_line(once "[1mUnknown remote: #(1)[0m" # command.first)
                  end
               end
            end
         end
      end

   help_list_remotes: ABSTRACT_STRING is
      do
         if remote_map.is_empty then
            Result := once "There are no remotes defined."
         elseif remote_map.count = 1 then
            Result := once "There is only one remote defined: [1m#(1)[0m" # remote_map.key(remote_map.lower)
         else
            Result := once "The defined remotes are:%N                   [1m#(1)[0m" # list_remotes
         end
      end

   config_remote_sections: FIXED_STRING is
      once
         Result := "remote.sections".intern
      end

   make is
      do
         create remote_map.make
         Precursor
      end

invariant
   remote_map /= Void

end
