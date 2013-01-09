#!/bin/bash

# note that this script assumes it has been placed in the rails application bin or script directory
NAMESPACE="resque"
ENVIRONMENT=${RAILS_ENV:=development}
FILE_PATH=$(cd `/usr/bin/dirname $0`; pwd -P)
QUEUE="critical"
CLASS="fetch"
ARGS="$(/bin/date '+%s')"

usage()
{
cat << EOF
usage: $0 options

This script places a job onto a resque queue

OPTIONS:
  -h      Show this message
  -s      Set the server (default is localhost or settings based on RAILS_ENV and config/resque.yml
  -p      Server root port (default is 6379 or settings based on RAILS_ENV and config/resque.yml
  -q      Resque queue name (default is critical)
  -c      Class name for the resque queue (default is ResqueRecipeKickoffWorker)
  -a      Args for the class (default is current time in seconds)
EOF
}

while getopts ":h:s:p:q:c:e:a" opt; do
  case $opt in
    h)
      usage
      exit 1
      ;;
    s)
      HOST=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    q)
      QUEUE=$OPTARG
      ;;
    c)
      CLASS=$OPTARG
      ;;
    e)
      ENVIRONMENT=$OPTARG
      ;;
    a)
      ARGS=$OPTARG
      ;;
    \?)
      usage
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ -e ${FILE_PATH}/../config/resque.yml ]
then
  HOST="$(awk -F ':' "/^${ENVIRONMENT}\:\s*/{ print \$2 }" ${FILE_PATH}/../config/resque.yml | sed 's/^[ \t]*//')"
  PORT="$(awk -F ':' "/^${ENVIRONMENT}\:\s*/{ print \$3 }" ${FILE_PATH}/../config/resque.yml | sed 's/^[ \t]*//')"
else
  HOST="localhost"
  PORT="6379"
fi

/usr/local/bin/redis-cli -h $HOST -p $PORT SADD "${NAMESPACE}:queues" "${QUEUE}"
/usr/local/bin/redis-cli -h $HOST -p $PORT RPUSH "${NAMESPACE}:queue:${QUEUE}" "{\"class\":\"${CLASS}\",\"args\":${ARGS}}"
echo "Done."
