#!/bin/sh

# Position at first step
first_tag=$(git describe --tags "$(git tag -l | sort -n | head -n 1)")
git checkout "$first_tag"

# Clone the repo in another location for solution
remote_url=$(git remote get-url origin)
git clone -b "$first_tag" "$remote_url" "$HOME/environment/terraform-aws-lab-solution"

cd infra || exit
