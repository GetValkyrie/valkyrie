#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Publish Avahi MDNS CNAME records for the local server.

This daemon will scan a set of configuration files
(/etc/avahi/aliases, any file in/etc/avahi/aliases.d and whatever
files in the --directory argument) and attempt to tell Avahi to
announce the names listed in those files (one per line) as CNAME
records to the local server.

Inspired by:

 * http://www.avahi.org/wiki/PythonPublishExample
 * https://github.com/PraxisLabs/avahi-aliases

Requires:

 * python-gobject
 * python-avahi
 * python-dbus

Author: Antoine Beaupré <anarcat@koumbit.org>
"""

import os
import signal
import logging
import logging.handlers
import argparse
import dbus
import gobject
import avahi
from encodings.idna import ToASCII
from dbus.mainloop.glib import DBusGMainLoop

class Settings:
    # Got these from /usr/include/avahi-common/defs.h
    TTL = 60
    CLASS_IN = 0x01
    TYPE_CNAME = 0x05

    ALIASES_CONFIG = "/etc/avahi/aliases"
    ALIAS_CONF_PATH = "/etc/avahi/aliases.d"
    ALIAS_DEFINITIONS =[ os.path.join(ALIAS_CONF_PATH, config_file) for config_file in os.listdir(ALIAS_CONF_PATH) ] + [ ALIASES_CONFIG ]

    # Counter so we only rename after collisions a sensible number of times
    RENAME_COUNT = 12

    @classmethod
    def get_aliases(cls):
        """ Steps through all config alias files and builds a set of aliases """
        aliases = set()
        for config_file_path in cls.ALIAS_DEFINITIONS:
            try:
                config_file = open(config_file_path, 'r')
                for line in config_file :
                    entry = line.strip('\n')
                    if len(entry) > 0 and not entry.startswith("#"):
                        aliases.add(entry)
                config_file.close()
            except IOError:
                pass
        return aliases

class AvahiAliases:
    def __init__(self, *args, **kwargs):
        self.group = None #our entry group
        self.rename_count = Settings.RENAME_COUNT
        DBusGMainLoop( set_as_default=True )

        self.server = dbus.Interface(
            dbus.SystemBus().get_object( avahi.DBUS_NAME, avahi.DBUS_PATH_SERVER ),
            avahi.DBUS_INTERFACE_SERVER )
        self.server.connect_to_signal( "StateChanged", self.server_state_changed )

    def run(self):
        """main loop of this program is here"""
        signal.signal(signal.SIGTERM, self.handle_interrupt)
        signal.signal(signal.SIGHUP, self.handle_reload)

        # prime it
        self.server_state_changed( self.server.GetState() )

        try:
            gobject.MainLoop().run()
        except KeyboardInterrupt:
            pass

        if not self.group is None:
            self.group.Free()

    def handle_interrupt(self, sig, no):
        """any signal thrown here will raise an exception"""
        raise KeyboardInterrupt

    def handle_reload(self, sig, no):
        """handler for SIGHUP: stop and start everything"""
        self.remove_service()
        self.add_service()

    def encode(self, name):
        """ convert the string to ascii
            copied from https://gist.github.com/gdamjan/3168336
        """
        return '.'.join( ToASCII(p) for p in name.split('.') if p )


    def encode_rdata(self, name):
        """
            copied from https://gist.github.com/gdamjan/3168336
        """
        def enc(part):
            a = ToASCII(part)
            return chr(len(a)), a
        return ''.join( '%s%s' % enc(p) for p in name.split('.') if p ) + '\0'

    def add_service(self):
        """core functionality is here: announce the aliases to Avahi through DBUS"""

        """create an EntryGroup to send our records"""
        if self.group is None:
            self.group = dbus.Interface(
                    dbus.SystemBus().get_object( avahi.DBUS_NAME, self.server.EntryGroupNew()),
                    avahi.DBUS_INTERFACE_ENTRY_GROUP)
            self.group.connect_to_signal('StateChanged', self.entry_group_state_changed)

        # count successful records
        records = 0
        for cname in Settings.get_aliases():
            logging.info("Adding service '%s' of type '%s' ..." % (cname, 'CNAME'))
            # format the data for consumption by avahi
            cname = self.encode(cname)
            rdata = self.encode_rdata(self.server.GetHostNameFqdn())
            rdata = avahi.string_to_byte_array(rdata)

            # add a CNAME record pointing to the local FQDN for every alias provided
            try:
                self.group.AddRecord(avahi.IF_UNSPEC, avahi.PROTO_UNSPEC, dbus.UInt32(0),
                                     cname, Settings.CLASS_IN, Settings.TYPE_CNAME,
                                     Settings.TTL, rdata)
            except dbus.exceptions.DBusException as e:
                if 'org.freedesktop.Avahi.NotSupportedError' in str(e):
                    logging.warning("cname %s not supported by avahi, try appending .local" % cname)
                else:
                    raise
            else:
                records += 1
        if records > 0:
            logging.debug("committing")
            self.group.Commit()

    def remove_service(self):
        """remove the announced records from avahi"""
        if not self.group is None:
            self.group.Reset()

    def server_state_changed(self, state):
        """handle server state changes

        this is how we get told to add or remove records most of the
        time.
        """
        logging.debug("server state change: %s" % state)
        if state == avahi.SERVER_COLLISION:
            logging.warning("WARNING: Server name collision")
            self.remove_service()
        elif state == avahi.SERVER_RUNNING:
            self.add_service()

    def entry_group_state_changed(self, state, error):
        """watch the group we have created to deal with conflicts"""
        logging.debug("state change: %i" % state)

        # it was setup properly, log it
        if state == avahi.ENTRY_GROUP_ESTABLISHED:
            logging.info("Service established.")
        elif state == avahi.ENTRY_GROUP_COLLISION:
            self.rename_count = self.rename_count - 1
            if self.rename_count > 0:
                # XXX: it is likely this code doesn't work
                # see also http://lists.freedesktop.org/archives/avahi/2011-August/002078.html
                logging.warning("WARNING: Service name collision, changing name to '%s' ..." % 
                                self.server.GetAlternativeServiceName(name))
                self.remove_service()
                self.add_service()
            else:
                logging.error("ERROR: No suitable service name found after %i retries, exiting." %
                              Settings.RENAME_COUNT)
                main_loop.quit()
        elif state == avahi.ENTRY_GROUP_FAILURE:
            logging.error("Error in group state changed", error)
            main_loop.quit()
            return

def parse_args():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('-d', '--directory', action='store', help='another directory to parse aliases from')
    parser.add_argument('-v', '--verbose', dest='verbose', default=False, action='store_true',
                        help='explain what we do along the way')
    parser.add_argument('--debug', dest='debug', default=False, action='store_true',
                        help='more verbosity')
    args = parser.parse_args()
    if args.directory:
        Settings.ALIAS_DEFINITIONS += [ os.path.join(args.directory, config_file) for config_file in os.listdir(args.directory) ]
    return args

def daemon_logging(args):
    """setup standard daemon logging

    that is: by default, everything above info goes on stderr, and
    everything goes out to syslog

    also, args.debug switch to DEBUG and args.verbose switch to INFO
    for stderr.
    """
    slfmt = logging.Formatter('%(filename)s[%(process)d]: %(message)s')
    sl = logging.handlers.SysLogHandler(address='/dev/log')
    sl.setFormatter(slfmt)
    logging.getLogger('').addHandler(sl)
    # log everything and let syslog sort it out
    logging.getLogger('').setLevel(logging.DEBUG)
    sh = logging.StreamHandler()
    if args.debug:
        sh.setLevel(logging.DEBUG)
    elif args.verbose:
        sh.setLevel(logging.INFO)
    else:
        sh.setLevel(logging.WARNING)
    logging.getLogger('').addHandler(sh)

if __name__ == '__main__':
    daemon_logging(parse_args())

    AvahiAliases().run()
