terraform
===============

## How to Use

### WordPress

1. git clone and Change Directory
  ```
  $ git clone https://this.repository terraform
  $ cd terraform/wordpress
  ```

2. Create a key-pair
  ```
  $ ssh-keygen
  > ~/.ssh/id-rsa
  > ~/.ssh/id-rsa.pub
  ```
  
3. Configure "terraform.tfvars" file
  ```
  $ cp terraform.tfvars.example terraform.tfvars
  ```

4. Run terrafrom
  ```
  ($ terrafrom plan)
  $ terrafrom apply
  ```
