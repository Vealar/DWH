#!/bin/bash
set -e

sh /etc/postgresql/bash-scripts/add_user.sh
sh /etc/postgresql/bash-scripts/basebackup.sh
sh /etc/postgresql/bash-scripts/change_configs.sh
