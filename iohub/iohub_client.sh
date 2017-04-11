#! /bin/bash


# Trivial wrappers
# Copy input data on job start, upload results on finit
SSH="ssh -i  /iohub/key -oStrictHostKeyChecking=no -oBatchMode=yes $@"
SCP="scp -i  /iohub/key -oStrictHostKeyChecking=no -oBatchMode=yes $@"

function job_prep
{
	$SCP -r $IOHOB_JOB_INPUT /job/input
}

function job_done
{
	
	$SCP -r /job/result $IOHOB_JOB_OUT 
}
