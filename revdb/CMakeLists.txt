# revdb - Database Access External
# Provides database connectivity (MySQL, PostgreSQL, SQLite, ODBC)

message(STATUS "Configuring revdb")

# This external provides database access functionality
# It's loaded at runtime as a plugin

# For now, skip revdb as it requires additional setup
# The sources exist but need proper external library integration
message(STATUS "revdb: skipping (requires database library integration)")

# TODO: Proper implementation would include:
# - revdb core library
# - dbmysql, dbpostgresql, dbsqlite, dbodbc driver modules
