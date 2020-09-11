[![Build Status](https://app.codeship.com/projects/0b7198d0-d64c-0138-2bc6-022c34f98bcc/status?branch=development)](https://app.codeship.com/projects/0b7198d0-d64c-0138-2bc6-022c34f98bcc/status?branch=development)

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

`git clone https://github.com/kintyre/quail-hollow-2`

### Download the a release

<https://github.com/Kintyre/quail-hollow-2/releases>

### Change mode

Make the file executable

`sudo chmod +x setup.sh`

### Options

**--help, -h**
Shows helpul usage information

#### Parameters

Provide text after parameter option name seperated by space

`--alias, -a`

The alias is used to set the IAM account alias (see <https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html#AboutAccountAlias>) and/or prefix various globally unique AWS resource names and/or identifiers such as S3 bucket names;  if an alias is not specified, it will default to the AWS account number.  The prefix must comply with S3 naming convention requirements (see <https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html>)

`--profile, -p`

The AWS CLI configured profile to use;  will use the default/active profile if not specified

`--region, -r`

AWS region to use with CLI commands;  will attempt to use region from profile if not specified

`--command, -c`

The feature/command representing a particular best practice to implement.  Defaults to all.

- **all** - runs all the commands below

- **iamAlias** - attempts to set the account's IAM alias

- **vpc** - creates a VPC using the included CloudFormation template (uploaded to an S3 bucket);  vpc.yaml based on: https://docs.aws.amazon.com/quickstart/latest/vpc/welcome.html

- **CloudTrail** - creates an S3 bucket, with properly configured policy, and turns on CloudTrail to output to S3

- **Config** - creates S3 bucket, with properly configured policy, and SNS topic, to record Config results in S3

- **Billing** - creates S3 bucket, with properly configured policy, to output cost and usage reports to S3 for further analysis;  see https://docs.aws.amazon.com/cur/latest/userguide/cur-create.html for next steps

### Examples

`./setup.sh --alias "AcmeStaging" --region us-west-1 --command iamAlias`

`./setup.sh --profile "AcmeTest" `

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

### Branching Strategy

<https://nvie.com/posts/a-successful-git-branching-model/>

### Testing

To help with testing, consider:  https://dev.to/michrodz/cloud-reset-reset-a-cloud-aws-gcp-azure-account-to-default-deleting-all-unneded-resources-updated-ggd, https://github.com/rebuy-de/aws-nuke
