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

Author:

 * Antoine Beaupré <anarcat@koumbit.org>
"""

import os
import signal
import logging
import argparse
import dbus
import gobject
import avahi
from encodings.idna import ToASCII
from dbus.mainloop.glib import DBusGMainLoop

rename_count = 12 # Counter so we only rename after collisions a sensible number of times

class Settings:
    # Got these from /usr/include/avahi-common/defs.h
    TTL = 60
    CLASS_IN = 0x01
    TYPE_CNAME = 0x05

    ALIASES_CONFIG = "/etc/avahi/aliases"
    ALIAS_CONF_PATH = "/etc/avahi/aliases.d"
    ALIAS_DEFINITIONS =[ os.path.join(ALIAS_CONF_PATH, config_file) for config_file in os.listdir(ALIAS_CONF_PATH) ] + [ ALIASES_CONFIG ]

class AvahiAliases:
    def __init__(self, *args, **kwargs):
        self.group = None #our entry group

    def get_aliases(self, path=None):
        """ Steps through all config alias files and builds a set of aliases """
        aliases = set()
        for config_file_path in path :
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
        if self.group is None:
            self.group = dbus.Interface(
                    bus.get_object( avahi.DBUS_NAME, server.EntryGroupNew()),
                    avahi.DBUS_INTERFACE_ENTRY_GROUP)
            self.group.connect_to_signal('StateChanged', self.entry_group_state_changed)

        for cname in self.get_aliases(Settings.ALIAS_DEFINITIONS):
            logging.info("Adding service '%s' of type '%s' ..." % (cname, 'CNAME'))
            cname = self.encode(cname)
            rdata = self.encode_rdata(server.GetHostNameFqdn())
            rdata = avahi.string_to_byte_array(rdata)
            records = 0

            try:
                self.group.AddRecord(avahi.IF_UNSPEC, avahi.PROTO_UNSPEC, dbus.UInt32(0),
                                cname, Settings.CLASS_IN, Settings.TYPE_CNAME,
                                Settings.TTL, rdata)
            except dbus.exceptions.DBusException as e:
                if 'org.freedesktop.Avahi.NotSupportedError' in str(e):
                    logging.warning("cname %s not supported by avahi" % cname)
                else:
                    raise
            else:
                records += 1
        if records > 0:
            logging.debug("committing")
            self.group.Commit()

    def remove_service(self):
        if not self.group is None:
            self.group.Reset()

    def server_state_changed(self, state):
        logging.debug("server state change: %s" % state)
        if state == avahi.SERVER_COLLISION:
            logging.warning("WARNING: Server name collision")
            self.remove_service()
        elif state == avahi.SERVER_RUNNING:
            self.add_service()

    def entry_group_state_changed(self, state, error):
        global serviceName, server, rename_count

        logging.debug("state change: %i" % state)

        if state == avahi.ENTRY_GROUP_ESTABLISHED:
            logging.info("Service established.")
        elif state == avahi.ENTRY_GROUP_COLLISION:

            rename_count = rename_count - 1
            if rename_count > 0:
                name = server.GetAlternativeServiceName(name)
                logging.warning("WARNING: Service name collision, changing name to '%s' ..." % name)
                self.remove_service()
                self.add_service()

            else:
                logging.error("ERROR: No suitable service name found after %i retries, exiting." % n_rename)
                main_loop.quit()
        elif state == avahi.ENTRY_GROUP_FAILURE:
            logging.error("Error in group state changed", error)
            main_loop.quit()
            return

def parse_args():
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--directory', action='store', help='another directory to parse aliases from')
    parser.add_argument('-v', '--verbose', dest='verbose', default=False, action='store_true',
                        help='explain what we do along the way')
    parser.add_argument('--debug', dest='debug', default=False, action='store_true',
                        help='more verbosity')
    args = parser.parse_args()
    if args.directory:
        Settings.ALIAS_DEFINITIONS += [ os.path.join(args.directory, config_file) for config_file in os.listdir(args.directory) ]
    if args.verbose:
        logging.basicConfig(level=logging.INFO)
    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
    # TODO: log to syslog as well?

def handle_signal(sig, no):
    raise KeyboardInterrupt

def handle_reload(sig, no):
    process.group.Reset()
    process.server_state_changed( server.GetState() )

if __name__ == '__main__':
    parse_args()

    DBusGMainLoop( set_as_default=True )

    main_loop = gobject.MainLoop()
    bus = dbus.SystemBus()

    server = dbus.Interface(
            bus.get_object( avahi.DBUS_NAME, avahi.DBUS_PATH_SERVER ),
            avahi.DBUS_INTERFACE_SERVER )

    process = AvahiAliases(server)

    server.connect_to_signal( "StateChanged", process.server_state_changed )
    process.server_state_changed( server.GetState() )

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGHUP, handle_reload)
    
    try:
        main_loop.run()
    except KeyboardInterrupt:
        pass

    if not process.group is None:
        process.group.Free()
