#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
# 無料プランはShellが使えないため、seedもビルド時に実行する（投入済みならスキップされる）
bundle exec rails db:seed