#!/bin/sh
set -e

# On first run (empty volume), copy initial blog content to the mounted data directory
if [ -z "$(ls -A /app/public/blogs 2>/dev/null)" ]; then
  echo "Initializing blog data..."
  cp -r /app/public-initial/blogs/. /app/public/blogs/
  echo "Blog data initialized."
fi

exec "$@"
