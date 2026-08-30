#!/usr/bin/env bash

cd ./server

bun db:generate
bun db:migrate

echo "all tasks completed"

bun start:dev
