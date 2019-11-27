#!/bin/bash
set -e  -u

if [ -f /firstboot.tmp ] ;
then

    su   postgres  -c psql < /firstboot.sql
    freshclam
    supervisorctl start clamd
    rm -f /firstboot.tmp /firstboot.sql


fi