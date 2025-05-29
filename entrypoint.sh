#!/bin/sh
set -e

# Ensure the data directory is owned by nobody
chown -R nobody /app/priv/data

# Now run the main container command
exec "$@"
