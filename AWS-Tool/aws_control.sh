#!/bin/bash

while [ "$1" != "" ]; do
    case $1 in
        -h | --help )
            echo "Usage: aws_control.sh [options]"
            echo "Options:"
            echo "  -h, --help    Show this help message"
            echo "  -s, --start   Start ec2 instance"
            echo "  -x, --stop   Start ec2 instance"
            echo "  -l, --list   List ec2 instances and their IP addresses"
            ;;
        -s | --start )
            aws ec2 start-instances --instance-ids i-0c46eadee5de2972e
            ;;
        -x | --stop )
            aws ec2 stop-instances --instance-ids i-0c46eadee5de2972e
            ;;
        -l | --list )
            aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, PublicIpAddress]' --output table
            ;;
        * )
            echo "Invalid option: $1"
            exit 1
    esac
    shift
done
