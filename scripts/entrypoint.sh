#!/bin/bash
set -e

mix ecto.create && mix ecto.migrate

exec "$@"

