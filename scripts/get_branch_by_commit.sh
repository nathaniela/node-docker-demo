#!/bin/bash

echo "get_branch_by_commit: checking branches"
echo `git branch`
echo "get_branch_by_commit: looking for branches with commit ${1}"
branch=`git branch --contains ${1} | grep -v master`
echo "get_branch_by_commit: found branch ${branch}"
return "${branch}"
