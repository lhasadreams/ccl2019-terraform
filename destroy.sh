cd aws
for loop in {1..2}
do
    terraform workspace select st$loop

    # Apply the configuration to the workspace
    terraform destroy -auto-approve
    
    # Destroy the Gists
    cmd="gist -l | grep student$loop | sed 's/ .*//'"
    gistid=$(eval "$cmd")
    echo $gistid
    cmd="gist --delete $gistid"
    echo $cmd
    $(eval "$cmd")
done