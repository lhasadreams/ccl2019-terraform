cd aws
for loop in {1..3}
do
    terraform workspace select st$loop

    # Apply the configuration to the workspace
    terraform destroy -auto-approve
done