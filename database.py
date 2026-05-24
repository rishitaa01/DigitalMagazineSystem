"""
database.py — MySQL connection helper and schema initialization
Digital Magazine Management System
"""

import mysql.connector
import os

DB_CONFIG = {
    'host':     os.environ.get('MYSQLHOST',     'localhost'),
    'user':     os.environ.get('MYSQLUSER',     'root'),
    'password': os.environ.get('MYSQLPASSWORD', 'Rishita123*'),
    'database': os.environ.get('MYSQLDATABASE', 'magazine_system'),
    'port':     int(os.environ.get('MYSQLPORT', '3306')),
}

SCHEMA = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    'schema.sql'
)


def get_db():
    """Returns a new MySQL connection."""
    conn = mysql.connector.connect(**DB_CONFIG)
    return conn


def init_db():
    conn = get_db()
    cursor = conn.cursor()

    with open(SCHEMA, 'r', encoding='utf-8') as f:
        sql_script = f.read()

    # Split and execute statements one by one
    statements = [s.strip() for s in sql_script.split(';') if s.strip()]
    for statement in statements:
        try:
            cursor.execute(statement)
        except Exception:
            pass  # skip already-existing tables/indexes

    conn.commit()
    cursor.close()
    conn.close()
    print('[OK] MySQL database initialized')


if __name__ == '__main__':
    init_db()
