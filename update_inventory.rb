require 'aws-sdk'
require 'optparse'
require 'unindent'
require './credential'

def set_aws_credential(environment)
  case environment
  when "develop"
    { 
       "aws_access_key": DEV_AWS_ACCESS_KEY_ID,
       "aws_secret_key": DEV_AWS_SECRET_ACCESS_KEY,
       "aws_region": AWS_REGION
    }
  when "production"
    {
       "aws_access_key": PRD_AWS_ACCESS_KEY_ID,
       "aws_secret_key": PRD_AWS_SECRET_ACCESS_KEY,
       "aws_region": AWS_REGION
    }
  else
    puts "Error: Irregular environment specified."
    exit 1
  end
end

def get_public_ips_list(aws_credential, service_name, role_name)
  public_ip_array = []
  begin
    ec2_list = Aws::EC2::Client.new(
      access_key_id:     "#{aws_credential[:aws_access_key]}",
      secret_access_key: "#{aws_credential[:aws_secret_key]}",
      region:            "#{aws_credential[:aws_region]}"
    ).describe_instances(
      {
        filters: [
          { name: 'tag:Service',         values: ["#{service_name}"] },
          { name: 'tag:Role',            values: ["#{role_name}"] },
          { name: 'instance-state-name', values: ["running"] }
        ]
      }
    ).reservations.each do |reservation|
        reservation.instances.each do |instance|
          public_ip_array << instance.public_ip_address
        end
      end
    public_ip_array
  rescue => err
    puts err
    exit 1
  end
end

def generate_inventory(public_ips, inventory_dir, service_name, ssh_user)
  inventory_file = File.open("#{inventory_dir}/inventory","w")
  inventory_file.puts("[#{service_name}]")
  public_ips.each do |ip|
    inventory_file.puts("#{ip} ansible_ssh_user=#{ssh_user}")
  end
  
  puts success_msg = <<-EOS.unindent

    Success Generated.

    Ansible inventory file generated or updated.
    The File on #{@inventory_dir}/inventory and your current dir is there.
    Execution sample is following.

    # ansible [service_name] -i inventory -m shell -a '[exec_command]'

  EOS
end

begin
  option={}
  OptionParser.new do |opt|
    opt.on('--env string',     'Specify your aws account environment-name.')         {|value| option[:env]     = value}
    opt.on('--service string', 'Specify the target EC2-instances Service-tag name.') {|value| option[:service] = value}
    opt.on('--role string',    'Specify the target EC2-instances Role-tag name.')    {|value| option[:role]    = value}
    opt.on('--user string',    'Specify ssh-user name.')                             {|value| option[:user]    = value}
    opt.parse!(ARGV)
  end
  %W(#{option[:env]} #{option[:service]} #{option[:role]} #{option[:user]}).each do |option|
    if option.length == 0
      puts "Error: Argument is missing."
      exit 1
    end
  end
rescue => err
  puts err
  exit 1
end

credential = set_aws_credential(option[:env])
public_ips = get_public_ips_list(credential, option[:service], option[:role])
generate_inventory(public_ips, @inventory_dir, option[:service], option[:user])
