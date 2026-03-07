#!/bin/sh
set -e

echo "Running database migrations..."
flask db upgrade

echo "Starting Flask app..."
exec python app.py
