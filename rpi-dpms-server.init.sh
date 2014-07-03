#! /bin/sh

### BEGIN INIT INFO
# Provides:		rpi-dpms-server
# Required-Start:	$network
# Required-Stop:	$network
# Default-Start:	2 3 4 5
# Default-Stop:		
# Short-Description:	RPI DPMS server (HDMI port on/off daemon)
### END INIT INFO

set -e

. /lib/lsb/init-functions

case "$1" in
  start)
	log_daemon_msg "Starting DPMS server for RPI" "rpi-dpms-server" || true
	if start-stop-daemon --start --quiet --oknodo --pidfile /var/run/rpi-dpms-server.pid --exec /usr/local/sbin/rpi-dpms-server.pl --; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;
  stop)
	log_daemon_msg "Stopping DPMS server for RPI" "rpi-dpms-server" || true
	if start-stop-daemon --stop --quiet --oknodo --pidfile /var/run/rpi-dpms-server.pid; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;
  reload|force-reload)
	log_daemon_msg "Reloading DPMS server for RPI" "rpi-dpms-server" || true
	if start-stop-daemon --stop --signal 1 --quiet --oknodo --pidfile /var/run/rpi-dpms-server.pid --exec /usr/local/sbin/rpi-dpms-server.pl; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;

  restart)
	log_daemon_msg "Restarting DPMS server for RPI" "rpi-dpms-server" || true
	start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile /var/run/rpi-dpms-server.pid
	if start-stop-daemon --start --quiet --oknodo --pidfile /var/run/rpi-dpms-server.pid --exec /usr/local/sbin/rpi-dpms-server.pl --; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;

  status)
	status_of_proc -p /var/run/rpi-dpms-server.pid /usr/local/sbin/rpi-dpms-server.pl rpi-dpms-server.pl && exit 0 || exit $?
	;;

  *)
	log_action_msg "Usage: /etc/init.d/rpi-dpms-server {start|stop|reload|force-reload|restart|try-restart|status}" || true
	exit 1
esac

exit 0
