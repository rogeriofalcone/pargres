#!/bin/bash

echo "Starting all postgres instances..."

. ./paths.sh
U=`whoami`

pkill -e postgres
ulimit -c unlimited

hosts="localhost"
ports="5433"
for (( node=1; node<$1; node++ ))
do
	hosts="$hosts, localhost"
	ports="$ports, $((5433+node))"
done

echo "hosts: $hosts, ports: $ports"

for (( node=0; node<$1; node++ ))
do
	echo "node: $node"
	pgdata_dir="PGDATA"$node
	port=$((5433+$node))
	echo "pgdata_dir: $pgdata_dir, port: $port"
	rm -rf $pgdata_dir
	mkdir $pgdata_dir
	initdb -D $pgdata_dir > init
	
	echo "shared_preload_libraries = 'pargres'" >> $pgdata_dir/postgresql.conf
	echo "pargres.node = $node" >> $pgdata_dir/postgresql.conf
	echo "pargres.nnodes = $1" >> $pgdata_dir/postgresql.conf
	echo "pargres.hosts = '$hosts'" >> $pgdata_dir/postgresql.conf
	echo "pargres.ports = '$ports'" >> $pgdata_dir/postgresql.conf
	echo "pargres.eports = 1000" >> $pgdata_dir/postgresql.conf
	
	echo "parallel_setup_cost = 0.0" >> $pgdata_dir/postgresql.conf
	echo "parallel_tuple_cost = 0.0" >> $pgdata_dir/postgresql.conf
	echo "force_parallel_mode = 'off'" >> $pgdata_dir/postgresql.conf
	echo "min_parallel_table_scan_size = 0MB" >> $pgdata_dir/postgresql.conf
	echo "lc_messages='en_US.utf8'" >> $pgdata_dir/postgresql.conf
	
	rm logfile$node
	pg_ctl -c -D $pgdata_dir -l logfile$node -o "-p $port" start
	createdb -p $port $U
	psql -p $port -c "CREATE EXTENSION pargres;"
done
