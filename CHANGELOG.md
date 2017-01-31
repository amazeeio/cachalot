# Change Log
All notable changes to this project will be documented in this file.

## Unreleased

## 0.12.0 - 2017-01-31

## 0.12.0 - 2017-01-31

- Added MailHog, check https://docs.amazee.io/changelog.html how to use it :)

## 0.11.2 - 2016-11-14

- merged https://github.com/amazeeio/cachalot/pull/2 "Update dnsmasq version to 2.76"

## 0.11.1 - 2016-05-21

## 0.11.0 - 2016-05-21

- you can also call amazeeio-cachalot via the cachalot command
- destroy command does not try to stop the docker containers, as sometimes the docker itself is broken and that's why you like to destroy the vm
- no black color background for messages anymore
- restart=always for the dnsmasq container
- cachalot stop does not remove the shared docker containers anymore it just stops them

## 0.10.2 - 2016-05-01

- refactored so that shared Docker Containers are started directly by cachalot
- Added some more new functionalities for the Docker Containers
- Some better colloring and outputs during starting

## 0.10.1 - 2016-05-01

## 0.9.9 - 2016-04-22

- renamed shellinit to env

## 0.9.8 - 2016-04-22

## 0.9.7 - 2016-04-22

## 0.9.7 - 2016-04-22

- Better documentation
- Some improvements on what is going on during creating a machine
- Better output around shellinit

## 0.9.6 - 2016-03-31

## 0.9.5 - 2016-03-28
- Removed HTTP Proxy and SSH Agent, as they are now in the [amazeeio docker](https://github.com/AmazeeIO/amazeeio-docker) composer files

## 0.9.0 - 2016-03-28

### Changed
- Initial release of Cachalot, fully forked from [dinghy](https://github.com/codekitchen/dinghy). Thanks to [codekitchen](https://github.com/codekitchen) for open sourcing it <3
