#!/bin/bash

# https://github.com/pnpm/pnpm/issues/5803#issuecomment-1974820613
pnpm config set store-dir /home/node/.local/share/pnpm/store

# Install dependencies
cd src/web
pnpm install
