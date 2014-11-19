#!/usr/bin/python

import signal
import MySQLdb

from cement.core import backend, foundation, controller, handler, exc, hook
from cement.utils.misc import init_defaults

defaults = init_defaults('myapp', 'database')
defaults['database']['foo'] = 'bar'

# Hook to handle signals
def skynet_signal_handler(signum, frame):
    # do something with signum/frame
    if signum == signal.SIGTERM:
        print("Caught signal SIGTERM...")
        # do something to handle signal here
    elif signum == signal.SIGINT:
        print("Caught signal SIGINT...")
        # do something to handle signal here

# define an application base controller
class SkynetBaseController(controller.CementBaseController):
    class Meta:
        label = 'base'
        description = "Skynet is an experimental replacement for Aegir's queue daemon."

        arguments = [
            (['-c', '--config_file'], dict(action='store', help='The path to the config file to use.')),
            (['-v', '--verbose'], dict(action='store_true', help='Increase application verbosity.')),
            ]

    @controller.expose(hide=True, aliases=['run'])
    def default(self):
        self.app.log.info('Inside base.default function.')

    @controller.expose(aliases=['q'], help="Run a queue daemon.")
    def queued(self):
        self.app.log.info("Inside base.queued function.")
        if self.app.pargs.config_file:
            self.app.log.info("Using config file at '%s'." % \
                          self.app.pargs.config_file)
            app.config.parse_file(self.app.pargs.config_file)
        else:
            app.config.parse_file('~/skynet.conf')
        if self.app.pargs.verbose:
            for slug in app.config.keys('database'):
                self.app.log.info("Database option '%s' = %s" % (slug, app.config.get('database',slug)))
            for slug in app.config.get_sections():
                self.app.log.info("Section '%s'" % slug)

        from time import sleep
        #self.app.daemonize()

        while True:
            db = MySQLdb.connect(host = app.config.get('database','host'),
                                 user = app.config.get('database','user'),
                               passwd = app.config.get('database','passwd'),
                                   db = app.config.get('database','db'))
            cur = db.cursor()
            cur.execute("SELECT t.nid\
                           FROM hosting_task t\
                     INNER JOIN node n\
                             ON t.vid = n.vid\
                          WHERE t.task_status = %s\
                       GROUP BY t.rid\
                       ORDER BY n.changed, n.nid ASC" % 0)
            for row in cur.fetchall() :
                import subprocess
                self.app.log.info("New task NID: '%s'" % row[0])
                subprocess.call('drush @hostmaster hosting-task %s --strict=0 --interactive=true' % row[0], shell=True)
            sleep(1)

class Skynet(foundation.CementApp):
    class Meta:
        label = 'skynet'
        base_controller = SkynetBaseController
        config_defaults = defaults
        arguments_override_config = True
        meta_override=['database']

# create the app
app = Skynet(extensions=['daemon'])

# Register our signal handling hook
hook.register('signal', skynet_signal_handler)

try:
    # setup the application
    app.setup()
    # Add arguments
    app.args.add_argument('--passwd', action='store', dest='passwd')
    # run the application
    app.run()
except exc.CaughtSignal as e:
    pass
finally:
    # close the app
    app.close()
