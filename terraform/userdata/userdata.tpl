#!/bin/bash

/usr/bin/gitlab-runner register --url "${gitlab_url}" --registration-token "${gitlab_runner_token}" --description "${gitlab_runner_name}" --non-interactive --executor shell
systemctl restart gitlab-runner