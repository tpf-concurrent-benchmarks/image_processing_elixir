#!/bin/sh

NAME=$1
SECRET=$2

iex --sname ${NAME} --cookie ${SECRET} -S mix