# ☸️ k8s-cli

A super simple Ruby CLI app to make working with Kubernetes just a tiny bit easier.

<img width="100%" alt="Screenshot 2020-06-18 at 17 37 53" src="https://user-images.githubusercontent.com/2060518/85041590-74b76280-b18a-11ea-97ae-b57e65367e83.png">

## Requirements
The only requirement is to have Ruby installed on your machine.

## Setup
- Install the dependencies: `bundle install`
- Create a configuration: `config/application.yml`  
  For reference, please see `config/application.yml.sample`
- Run the app: `./bin/k8s-cli`

## Features
- See memory/CPU utilisation of the pods
- Connect to a type of pod
- List the current HPA stats
- List the pods
- Change context