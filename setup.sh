#!/bin/bash
mkdir creds
cd aws
creds=../credentials.txt
student=../creds/
gistlist=../gistlist.txt
# Create the Student Info File
echo CCL 2019 Workshop credentials > $creds
echo CCL 2019 Workshop gists > $gistlist
for loop in {1..2}
do
    echo CCL 2019 Workshop credentials for Student $loop> $student/student$loop
    # Create a terraform workspace
    terraform workspace new st$loop
    terraform workspace select st$loop

    # Apply the configuration to the workspace
    terraform apply -auto-approve

    # Save the output
    username=$(terraform show -json | jq -r .values.outputs.a2_admin.value)
    password=$(terraform show -json | jq -r .values.outputs.a2_admin_password.value)
    token=$(terraform show -json | jq -r .values.outputs.a2_token.value)
    a2url=$(terraform show -json | jq -r .values.outputs.a2_url.value)
    echo Student $loop >> $creds
    echo Chef Automate >> $creds
    echo a2-url - $a2url >> $creds

    echo Workshop Document URL - https://bit.ly/2Wu3Mrr >> $student/student$loop
    echo Chef Automate >> $student/student$loop
    echo a2-url - $a2url >> $student/student$loop


    url="\"$a2url/api/v0/auth/teams\""
    tokenheader="\"api-token: $token\""
    header="\"accept: application/json\""
    # Create an A2 user and add them to the admins group
    # Get the admin groups id
    command="curl -X GET $url -H $tokenheader -H $header |jq -r '.teams[] | select(.name == \"admins\") | .id'"
    adminTeamId=$(eval "$command")
    echo $adminTeamId

    # Create a User and capture its id
    url="\"$a2url/api/v0/auth/users\""
    header2="\"Content-Type: application/json\""
    command="curl -X POST $url -H $tokenheader -H $header -H $header2 -d \"{\\\"name\\\": \\\"Chef Conf London 2019\\\", \\\"email\\\": \\\"ccl2019\\\", \\\"username\\\": \\\"st$loop\\\", \\\"password\\\": \\\"Cod3Can!\\\"}\" |jq -r '.id'"
    userId=$(eval "$command")
    echo $userId

    echo Username - st$loop >> $creds
    echo Password - Cod3Can! >> $creds
    echo Token - $token >> $creds

    echo Username - st$loop >> $student/student$loop
    echo Password - Cod3Can! >> $student/student$loop
    echo Token - $token >> $student/student$loop

    # Add the new user to the Admin group
    url="\"$a2url/api/v0/auth/teams/$adminTeamId/users\""
    command="curl -X POST $url -H $tokenheader -H $header -H $header2 -d \"{\\\"user_ids\\\": [ \\\"$userId\\\" ]}\" |jq"
    result=$(eval "$command")
    echo $result

    centos=$(terraform show -json | jq -r .values.outputs.student_workstation_public_dns.value)
    rhel7=$(terraform show -json | jq -r '.values.outputs.student_node_public_dns.value[0]')
    echo Centos Workstation  >> $creds
    echo Hostname - $centos  >> $creds
    echo Username - centos >> $creds
    echo Password - Cod3Can! >> $creds

    echo Centos Workstation  >> $student/student$loop
    echo Hostname - $centos  >> $student/student$loop
    echo Username - centos >> $student/student$loop
    echo Password - Cod3Can! >> $student/student$loop

    echo RHEL7 Node  >> $creds
    echo Hostname - $rhel7  >> $creds
    echo Username - ec2-user >> $creds
    echo Password - Cod3Can! >> $creds

    echo RHEL7 Node  >> $student/st$loop
    echo Hostname - $rhel7  >> $student/student$loop
    echo Username - ec2-user >> $student/student$loop
    echo Password - Cod3Can! >> $student/student$loop

    echo ______________________________________ >> $creds

    # Write out the Creds as a secret gist
    gistcmd="gist -ps $student/student$loop"
    gisturl=$(eval "$gistcmd")
    # Save the gist url for the student 
    echo Student $loop >> $gistlist
    echo URL = $gisturl >> $gistlist
    echo ______________________________________ >> $gistlist
done