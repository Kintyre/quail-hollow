# Overview

Script for setting up many AWS account best practices as authored by Kintyre.

## Target Audience

Any IT professional with basic Linux CLI experience with administrative access to an AWS account.

## Table of Contents

- [Prerequisites](#Prerequisites)
- [Usage](#Usage)
  - [Options](#Options)
  - [Examples](#Examples)
- [Contribution](#Contribution)
  - [License](#License)
  - [Contact](#Contact)

## Prerequisites

This script must be run from a Linux compatbile host or emulator.

AWS Command Line Interface (CLI) must be isntalled and configured with at least one profile.  See <https://aws.amazon.com/cli/> for more information.

## Usage

Get the script onto your host through one of the following options

### Clone this repo using Git

`
git clone https://github.com/kintyre/quail-hollow-2
`

### Download the a release

<https://github.com/Kintyre/quail-hollow-2/releases>

### Change mode

Make the file executable
`
sudo chmod +x setup.sh
`

### Options

**--help, -h**
Shows helpul usage information

#### Parameters

Provide text after parameter option name seperated by space

`**--alias, -a**`

The alias is used to set the IAM account alias (see <https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html#AboutAccountAlias>) and/or prefix various globally unique AWS resource names and/or identifiers such as S3 bucket names;  if an alias is not specified, it will default to the AWS account number.

`**--profile, -p**`

The AWS CLI configured profile to use;  will use the default/active profile if not specified

`**--region, -r**`

AWS region to use with CLI commands;  will attempt to use region from profile if not specified

`**--command, -c**`

The feature/command representing a particular best practice to implement.  Defaults to all.

- all - runs all the commands below

- iamAlias - attempts to set the account's IAM alias

### Examples

`
./setup.sh --alias "AcmeStaging" --region us-west-1
`

`
./setup.sh --profile "AcmeTest"
`

## Contribution

### License

This script and associated files enable setting up many AWS account best practices as authored by Kintyre.

Copyright (C) 2020  Kintyre Solutions, Inc.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

### Contact

<https://www.kintyre.co>

hello@kintyre.co

(888)636-0010

>2817 Kennedy Road  
Wilmington, DE 19810  
United States of America

## Branching Strategy

<https://nvie.com/posts/a-successful-git-branching-model/>
