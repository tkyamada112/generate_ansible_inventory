# generate_ansible_inventory

## Description
Generate ansible inventory file, based on the latest EC2 information.

- Assumed to be two environments. (DEV, PRD)

## Installation

```
bundle install
```

## Usage

Edit `credentials.rb` before execution.

```
# credentials
DEV_AWS_ACCESS_KEY_ID="xxx"
DEV_AWS_SECRET_ACCESS_KEY="xxx"
PRD_AWS_ACCESS_KEY_ID="xxx"
PRD_AWS_SECRET_ACCESS_KEY="xxx"
AWS_REGION="xxx"

# other
@inventory_dir = "xxx"
```

```
bundle exec ruby update_inventory.rb --env <Environment> --service <Service_name> --role <Role_name> --user <ssh_username>
```
