#!/bin/bash

#options
optionShowHelp=0

#global variables
profile=""
region=""
awsCliBaseCmd="aws "
accountNumber=""
accountAlias=""
command="all"

tempDir=$(mktemp -d)

#functions
show_overview()
{
    echo "                  Quail Hollow AWS Best Practices Setup Script"
    echo "      Copyright (C) 2020  Kintyre Solutions, Inc.  https://www.kintyre.co"
    echo "   This code comes with ABSOLUTELY NO WARRANTY; for details see LICENSE file."
    echo "         This is free software, and you are welcome to redistribute it"
    echo "      under certain conditions of the license details in the LICENSE file."
    echo
}

show_help()
{
   echo "Usage ./setup.sh [options]"
   echo "See readme.md for more information"
}

test_awsCliConfig()
{
    awsCliBaseCmd="aws"
    if [ "${profile}" != "" ] ; then
        awsCliBaseCmd="${awsCliBaseCmd} --profile=${profile}"
    fi

    echo "Checking AWS CLI credentials"
    if ! ${awsCliBaseCmd} sts get-caller-identity > /dev/null 2>&1
    then
        echo "Unable to locate credentials. You can configure credentials by running \"aws configure\""
        exit 1
    fi

    profileRegion="us-east-1"
    echo "Checking region config setting"
    if ${awsCliBaseCmd} configure list | grep "^ *region" | grep -q "not set"
    then
        echo "Unable to locate region in aws config, falling back to default \"${profileRegion}\""
        awsCliBaseCmd="${awsCliBaseCmd} --region=${profileRegion}"
    fi

}

show_options()
{
    echo "Options..."
    echo "  Profile: ${profile}"
    echo "  Region:  ${region}"
    echo "  Alias:   ${accountAlias}"
    echo "  Command: ${command}"
}

set_accountNumber()
{
    # add error handler if this command is not successful
    accountNumber=$(${awsCliBaseCmd} ec2 describe-security-groups --group-names 'Default' \
        --query 'SecurityGroups[0].OwnerId' --output text)
}

set_accountAlias()
{
    if [ "${accountAlias}" == "" ] ; then
        accountAlias=$accountNumber
    fi
}

show_settings()
{
    echo "Settings..."
    echo "  AWS CLI Base Command: ${awsCliBaseCmd}"
    echo "  Account #:            ${accountNumber}"
    echo "  Alias:                ${accountAlias}"
}

config_accountAlias()
{
    aliasFound="false"
    aliasExists=false
    for aa in $(${awsCliBaseCmd} iam list-account-aliases --query 'AccountAliases[*]' --output text)
    do
        # We found at least one alias.
        aliasExists=true

        # Did we find the alias that was passed in?
        if [ "${aa}" == "${accountAlias}" ] ; then
            aliasFound="true"
        fi
    done

    # As account aliases need to be globally unique, there's no way to know if
    # one is taken other than to attempt to create it.  If there's an error, the
    # name is likely already taken.
    # There can only be one alias per account so only try to create one if there isnt one already.
    if [ ${aliasExists} == false ] ; then
        if [ "${aliasFound}" == "false" ] ; then
            echo 'Attempting to create IAM account alias'
            if ${awsCliBaseCmd} iam create-account-alias --account-alias "${accountAlias}"
            then
                echo 'IAM Account alias set'
            fi
        fi
    else
        echo "An alias already exists for this account and will not be recreated."
    fi
}

# This function will orchestrate the creation of an admin group and user.
adminUser_Create()
{
    # Scope Constants
    ACCOUNT_ADMIN_IAM_GROUPNAME="${accountAlias}_accountAdmins"
    ACCOUNT_ADMIN_IAM_USERNAME="${accountAlias}_AdminUser"
    ACCOUNT_ADMIN_IAM_TEMPPASSWORD="${accountAlias}TMPPWD"

    adminUser_CreateGroup
    adminUser_CreateUser
}

# As part of the account setup there will be an option to create an admin user.  This function will
# create the admin group that this new user will belong to.
adminUser_CreateGroup()
{
    # Make sure the group does not already exist.
    groupFound="false"
    for group in $(${awsCliBaseCmd} iam list-groups --query 'Groups[*].GroupName' --output text)
    do
        # Did we find the group?
        if [ "${group}" == "${ACCOUNT_ADMIN_IAM_GROUPNAME}" ] ; then
            groupFound="true"
        fi
    done
    # Create the new group
    if [ ${groupFound} == "false" ] ; then
        echo "Creating IAM group ${ACCOUNT_ADMIN_IAM_GROUPNAME}"

        ${awsCliBaseCmd} iam create-group --group-name "${ACCOUNT_ADMIN_IAM_GROUPNAME}"

        # Assign the AWS managed policy to the group.
        ${awsCliBaseCmd} iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --group-name "${ACCOUNT_ADMIN_IAM_GROUPNAME}"

    else
    {
        echo "IAM Group ${ACCOUNT_ADMIN_IAM_GROUPNAME} already exists and will not be re-created"
    }
    fi
}

# As part of the account setup there will be an option to create an admin user.  This function will
# create the admin user and associate it to the admin group.
adminUser_CreateUser()
{
    groupFound="false"
    for group in $(${awsCliBaseCmd} iam list-groups --query 'Groups[*].GroupName' --output text)
    do
        # Did we find the group?
        if [ "${group}" == "${ACCOUNT_ADMIN_IAM_GROUPNAME}" ] ; then
            groupFound="true"
        fi
    done

    #If we found the group then make sure the user doesnt already exist
    if [ ${groupFound} == "true" ] ; then
    {
        #Does the user already exist?
        userExists="false"
        for user in $(${awsCliBaseCmd} iam list-users --query 'Users[*].UserName' --output text)
        do
            if [ "${user}" == "${ACCOUNT_ADMIN_IAM_USERNAME}" ] ; then
            {
                userExists="true"
            }
            fi
        done

        if [ ${userExists} == "true" ] ; then
        {
            echo "User ${ACCOUNT_ADMIN_IAM_USERNAME} already exists and will not be re-created"
        }
        else
        {
            # Create user
            echo "Creating IAM user ${ACCOUNT_ADMIN_IAM_USERNAME}"
            ${awsCliBaseCmd} iam create-user --user-name "${ACCOUNT_ADMIN_IAM_USERNAME}"

            # Add user to group
            echo "Associating user ${ACCOUNT_ADMIN_IAM_USERNAME} to group ${ACCOUNT_ADMIN_IAM_GROUPNAME}"
            ${awsCliBaseCmd} iam add-user-to-group \
                --group-name "${ACCOUNT_ADMIN_IAM_GROUPNAME}" \
                --user-name "${ACCOUNT_ADMIN_IAM_USERNAME}"

            # Create secret access key
            echo "Creating access key for user ${ACCOUNT_ADMIN_IAM_USERNAME}"
            ${awsCliBaseCmd} iam create-access-key --user-name "${ACCOUNT_ADMIN_IAM_USERNAME}"

            # Create login profile for the user
            tempPassword="TestPassword"
            echo "Creating login profile for user ${ACCOUNT_ADMIN_IAM_USERNAME}"
            ${awsCliBaseCmd} iam create-login-profile \
                --user-name "${ACCOUNT_ADMIN_IAM_USERNAME}" \
                --password "${ACCOUNT_ADMIN_IAM_TEMPPASSWORD}" \
                --password-reset-required

            echo "User login profile created,  UID = ${ACCOUNT_ADMIN_IAM_USERNAME},  Temp password = ${ACCOUNT_ADMIN_IAM_TEMPPASSWORD}"
        }
        fi
    }
    else
    {
        echo "IAM Group ${ACCOUNT_ADMIN_IAM_GROUPNAME} could not be found so no Admin user was created"
    }
    fi
}


make_bucket()
{
    for i in $(${awsCliBaseCmd} s3api list-buckets --query "Buckets[].Name" --output text)
    do
        if [ "${i}" == "${1}" ] ; then
            bucketExists=1
            break
        fi
    done
    if [ "${bucketExists}" == 1 ] ; then
        echo "S3 bucket ${1} already exists."
    else
        echo "Attempting to create S3 bucket ${1}"
        ${awsCliBaseCmd} s3 mb "s3://${1}"
    fi
}

create_vpc()
{
    echo "creating VPC....."
    bucketName=${accountAlias}-cloudformation-templates
    make_bucket "${bucketName}"

    # Copy the VPC template up to the working S3 bucket.  Cloud formation needs it in S3.
    ${awsCliBaseCmd} s3 cp vpc.yaml \
        "s3://${bucketName}/vpc.template.yaml"

    #Apply the VPC cloud formation template to the account.
    ${awsCliBaseCmd} cloudformation create-stack \
        --stack-name "vpc-${accountAlias}" \
        --template-url "https://${bucketName}.s3.amazonaws.com/vpc.template.yaml"

}

config_bucketpolicy()
{
    # Generate policy file from template
    templateFile="${tempDir}/$1.json"
    #shellcheck disable=SC2002
    cat "$1BucketPolicyTemplate.json" | \
        sed "s/ACCOUNTNUMBER/${accountNumber}/g" | \
        sed "s/ACCOUNTALIAS/${accountAlias}/g" | \
        sed "s/DATE/$(date +'%Y%m%d')/" > "${templateFile}"

    # Apply policy to bucket
    echo "Applying bucket policy to $2"
    ${awsCliBaseCmd} s3api put-bucket-policy \
            --bucket "$2" \
            --policy "file://${templateFile}"
    rm -f "${templateFile}"
}

enable_cloudtrail()
{
    echo "Enabling CloudTrail....."
    bucketName=${accountAlias}-cloudtrail
    make_bucket "${bucketName}"
    config_bucketpolicy "cloudtrail" "${bucketName}"
    #Does the trail already exist
    trailName=$(${awsCliBaseCmd} cloudtrail get-trail \
        --name "${accountAlias}-cloudtrail" \
        --query Trail.Name --output text 2> /dev/null)

    if [ "${trailName}" == "${accountAlias}-cloudtrail" ] ; then
        echo "Trail ${accountAlias}-cloudtrail already exists and will not be re-created."
    else
        echo "Creating trail ${accountAlias}-cloudtrail"
        ${awsCliBaseCmd} cloudtrail create-trail \
            --name "${accountAlias}-cloudtrail" \
            --s3-bucket-name "${bucketName}" \
            --is-multi-region-trail
        ${awsCliBaseCmd} cloudtrail start-logging --name "${accountAlias}-cloudtrail"
    fi
    echo "Finished CloudTrail setup!"
    echo -e
}

enable_config()
{
    echo "Enabling Config....."
    bucketName=${accountAlias}-config
    make_bucket "${bucketName}"
    config_bucketpolicy "config" "${bucketName}"

    #Does the config role already exist
    existingRoleName=$(${awsCliBaseCmd} iam get-role \
        --role-name "${accountAlias}-config-role" \
        --query Role.RoleName \
        --output text 2> /dev/null)

   if [ "${existingRoleName}" == "${accountAlias}-config-role" ] ; then
        echo "Role ${accountAlias}-config-role already exists and will not be created again."
    else
        echo "Creating config role ${accountAlias}-config-role."

        templateFile=${tempDir}/configRoleTrustPolicy.json
        # shellcheck disable=SC2002
        cat configRoleTrustPolicyTemplate.json | \
            sed "s/DATE/$(date +'%Y%m%d')/" > "${templateFile}"

        # Creates config role
        ${awsCliBaseCmd} iam create-role \
            --role-name "${accountAlias}-config-role" \
            --assume-role-policy-document "file://${templateFile}"
        ${awsCliBaseCmd} iam attach-role-policy \
            --role-name "${accountAlias}-config-role" \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSConfigRole
        rm -f "${templateFile}"
    fi

    # Create SNS service for Config Service
    topicFound="false"
    topicName=""
    for i in $(${awsCliBaseCmd} sns list-topics --query Topics[*].TopicArn --output text)
    do
        searchArn="arn:aws:sns:${region}:${accountNumber}:${accountAlias}-config-topic"
        if [ "${i}" == "${searchArn}" ] ; then
            topicFound="true"
            topicName="${i}"
        fi
    done

    if [ ${topicFound} == "true" ] ; then
        echo "SNS Topic ${topicName} was found and will not be re-created."
    else
        echo "Creating SNS Topic"
        ${awsCliBaseCmd} sns create-topic --name "${accountAlias}-config-topic"

        # Set Config Service to deliver config informtion to S3 and SNS under the given IAM role
        # May have to run this again if fails on first attempt
        #sleep 10
        ${awsCliBaseCmd} configservice subscribe \
            --s3-bucket "${accountAlias}-config" \
            --sns-topic "arn:aws:sns:${region}:${accountNumber}:${accountAlias}-config-topic" \
            --iam-role "arn:aws:iam::${accountNumber}:role/${accountAlias}-config-role"
    fi

    echo "End Config setup"
    echo -e

}

create_billingbucket()
{
    bucketName=${accountAlias}-billing
    make_bucket "${bucketName}"
    config_bucketpolicy "billing" "${bucketName}"
}

cleanup()
{
    if [ -n "${tempDir}" ] && [ -d "${tempDir}" ]
    then
        rm -rf "${tempDir}"
    fi
}

# main

# Clean up temp files when script exits, whether by successful completion
# exit signal or intgerruption.
trap cleanup EXIT

show_overview

# TODO:  Fix parsing of command line arguments.  For example
#        this works:        "./setup.sh --command vpc"
#        but this does not: "./setup.sh --command=vpc"

# read command line options
while [ "$1" != "" ]; do
    case $1 in
        -p | --profile )        shift
                                profile=$1
                                ;;
        -r | --region )         shift
                                region=$1
                                ;;
        -a | --alias )          shift
                                accountAlias=$1
                                ;;
        -c | --command )        shift
                                command=$1
                                ;;
        -h | --help )           optionShowHelp=1
                                break
                                ;;
    esac
    shift
done

if [ "${optionShowHelp}" == 1 ] ; then
     show_help
     exit 1
fi

show_options

test_awsCliConfig

set_accountNumber

set_accountAlias

show_settings

if [ "${command}" == "all" ] ; then
    config_accountAlias
    enable_cloudtrail
    create_vpc
    enable_config
    adminUser_Create
    exit 1
fi

if [ "${command}" == "iamAlias" ] ; then
    config_accountAlias
    exit 1
fi

if [ "${command}" == "vpc" ] ; then
    create_vpc
    exit 1
fi

if [ "${command}" == "CloudTrail" ] ; then
    enable_cloudtrail
    exit 1
fi

if [ "${command}" == "Config" ] ; then
    enable_config
    exit 1
fi

if [ "${command}" == "Billing" ] ; then
    create_billingbucket
    exit 1
fi

if [ "${command}"  == "AdminUser" ] ; then
    adminUser_Create
    exit 1
fi
