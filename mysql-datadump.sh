#!/bin/sh

set -xe

cd /home/ec2-user
wget https://s3-us-west-1.amazonaws.com/vader-lab/gridlabd-data/ieee123-aws_2017-03-07_2017-03-21.sql.Z
zcat *.Z | mysql --user=username --password=password
