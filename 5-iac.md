# 5 - Infrastructure as Code (IAC): Ansible en Terraform/OpenTofu

## Inleiding: Van handmatig naar automatisch infrastructuur beheer

**Het probleem van handmatige infrastructuur:**
Stel je voor: je moet 50 servers configureren, elk met dezelfde software, gebruikers, en instellingen. Handmatig zou dit dagen kosten, foutgevoelig zijn, en niet reproduceerbaar. Infrastructure as Code (IAC) lost dit op.

**Wat je zult leren:**
- Waarom Infrastructure as Code de toekomst is van IT-beheer
- Ansible: Configuratie management en automatisering
- Terraform/OpenTofu: Infrastructure provisioning en beheer
- Praktische hands-on ervaring met beide tools
- Best practices voor IAC in productie omgevingen

---

## Wat is Infrastructure as Code?

### Definitie
Infrastructure as Code (IAC) is het proces van het beheren en inrichten van computerhardware via machine-leesbare definitiebestanden, in plaats van fysieke hardwareconfiguratie of interactieve configuratietools.

### Voordelen van IAC
1. **Versiecontrole**: Infrastructuur wordt getrackt zoals code
2. **Reproduceerbaar**: Identieke omgevingen maken
3. **Schaalbaarheid**: Duizenden servers even gemakkelijk als één
4. **Documentatie**: De code ÍS de documentatie
5. **Testing**: Infrastructuur kan getest worden
6. **Samenwerking**: Teams kunnen samen aan infrastructuur werken

### IAC Tools categorieën

#### 1. **Configuration Management** (Ansible, Chef, Puppet)
- Configureert bestaande servers
- Installeert software, wijzigt instellingen
- Zorgt voor consistency tussen servers

#### 2. **Infrastructure Provisioning** (Terraform, CloudFormation)
- Maakt nieuwe infrastructuur aan
- Beheert cloud resources (VMs, netwerken, databases)
- Lifecycle management van infrastructuur

---

## Deel 1: Ansible - Configuration Management

### Wat is Ansible?

Ansible is een open-source automatiseringstool voor:
- **Configuration management**: Servers configureren
- **Application deployment**: Software uitrollen
- **Task automation**: Repetitieve taken automatiseren
- **Orchestration**: Complexe workflows beheren

### Ansible Architectuur

```
Control Node (je laptop/server)
├── Ansible Installation
├── Playbooks (YAML files)
├── Inventory (hosts file)
└── SSH Verbindingen
    ├── → Managed Node 1
    ├── → Managed Node 2
    └── → Managed Node 3
```

**Belangrijke kenmerken:**
- **Agentless**: Geen software nodig op doelservers
- **Idempotent**: Meerdere keren uitvoeren geeft zelfde resultaat
- **SSH-based**: Gebruikt bestaande SSH verbindingen
- **YAML syntax**: Gemakkelijk leesbaar en schrijfbaar

### Ansible Installatie

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# macOS
brew install ansible

# pip (alle systemen)
pip install ansible

# Verificatie
ansible --version
```

### Ansible Componenten

#### 1. Inventory File (hosts)
Het inventory bestand definieert welke servers Ansible moet beheren:

```ini
# 5-iac-files/ansible/hosts
[mycloudvms]
141.144.203.33
projectwerk.vives.be
linux.vives.live

[mycloudvms:vars]
ansible_user=root
ansible_password=P@ssword123

[ubuntu-servers]
141.148.235.108

[ubuntu-servers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

**Inventory groepen:**
- `[mycloudvms]`: Groep van cloud VMs
- `[ubuntu-servers]`: Groep Ubuntu servers
- `:vars`: Variabelen voor de groep

#### 2. Ansible Configuration (ansible.cfg)
```ini
[defaults]
host_key_checking = False
inventory = hosts
remote_user = root
private_key_file = ~/.ssh/id_rsa

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

#### 3. Ad-hoc Commands
Snelle commando's zonder playbooks:

```bash
# Test connectiviteit
ansible all -i hosts -m ping

# Systeem informatie
ansible mycloudvms -i hosts -a "cat /etc/os-release"

# Package installatie
ansible ubuntu-servers -i hosts -m apt -a "name=htop state=present" --become

# Service beheer
ansible all -i hosts -m systemd -a "name=nginx state=started enabled=yes" --become

# File operaties
ansible all -i hosts -m copy -a "src=/tmp/test.txt dest=/tmp/test.txt" 

# User management
ansible all -i hosts -m user -a "name=devops shell=/bin/bash groups=sudo" --become
```

**Veel gebruikte modules:**
- `ping`: Test connectiviteit
- `command`/`shell`: Commando's uitvoeren
- `apt`/`yum`: Package management
- `copy`/`file`: File operaties
- `user`/`group`: User management
- `systemd`/`service`: Service management

### Ansible Playbooks

Playbooks zijn YAML bestanden die complexe taken definiëren:

#### Basis Playbook structuur
```yaml
---
- name: Playbook naam
  hosts: doelgroep
  become: yes  # sudo privileges
  vars:
    variabele: waarde
  
  tasks:
    - name: Task beschrijving
      module:
        parameter: waarde
```

#### Praktisch voorbeeld: Server Setup

```yaml
# 5-iac-files/ansible/playbook.yaml
---
- name: Example Playbook for Ubuntu Servers
  hosts: all
  become: yes
  vars:
    new_user: devopsuser
    ssh_pub_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD..."

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Upgrade all packages
      apt:
        upgrade: dist

    - name: Install essential packages
      apt:
        name:
          - git
          - curl
          - htop
          - vim
          - docker.io
        state: present

    - name: Create a new user
      user:
        name: "{{ new_user }}"
        shell: /bin/bash
        state: present
        groups: sudo

    - name: Add SSH key for new user
      authorized_key:
        user: "{{ new_user }}"
        key: "{{ ssh_pub_key }}"

    - name: Ensure UFW is installed
      apt:
        name: ufw
        state: present

    - name: Allow SSH through firewall
      ufw:
        rule: allow
        name: OpenSSH

    - name: Enable UFW
      ufw:
        state: enabled
        enabled: yes

    - name: Start and enable Docker
      systemd:
        name: docker
        state: started
        enabled: yes
```

#### Simpel Playbook voorbeeld

```yaml
# 5-iac-files/ansible/playbook-createfile.yml
---
- name: My playbook
  hosts: all
  tasks:
     - name: Leaving a mark
       command: "touch /tmp/ansible_automated_file"
```

### Playbook uitvoeren

```bash
# Basis uitvoering
ansible-playbook -i hosts playbook.yaml

# Met verhoogde verbosity (debugging)
ansible-playbook -i hosts playbook.yaml -vvv

# Dry run (test zonder wijzigingen)
ansible-playbook -i hosts playbook.yaml --check

# Specifieke hosts
ansible-playbook -i hosts playbook.yaml --limit ubuntu-servers

# Met extra variabelen
ansible-playbook -i hosts playbook.yaml -e "new_user=milan"
```

### Geavanceerde Ansible Concepten

#### 1. Variables en Templates
```yaml
vars:
  packages:
    - nginx
    - mysql-server
  mysql_root_password: "secure123"

tasks:
  - name: Install packages
    apt:
      name: "{{ packages }}"
      state: present

  - name: Configure nginx
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: restart nginx
```

#### 2. Handlers (Event-driven tasks)
```yaml
tasks:
  - name: Copy nginx config
    copy:
      src: nginx.conf
      dest: /etc/nginx/nginx.conf
    notify: restart nginx

handlers:
  - name: restart nginx
    systemd:
      name: nginx
      state: restarted
```

#### 3. Conditionals
```yaml
tasks:
  - name: Install Apache on Ubuntu
    apt:
      name: apache2
      state: present
    when: ansible_distribution == "Ubuntu"

  - name: Install httpd on CentOS
    yum:
      name: httpd
      state: present
    when: ansible_distribution == "CentOS"
```

#### 4. Loops
```yaml
tasks:
  - name: Create multiple users
    user:
      name: "{{ item }}"
      state: present
    loop:
      - alice
      - bob
      - charlie

  - name: Install multiple packages
    apt:
      name: "{{ item.name }}"
      state: "{{ item.state }}"
    loop:
      - { name: nginx, state: present }
      - { name: apache2, state: absent }
```

### Ansible Best Practices

#### 1. Directory structuur
```
project/
├── ansible.cfg
├── hosts
├── group_vars/
│   ├── all.yml
│   └── webservers.yml
├── host_vars/
│   └── server1.yml
├── roles/
│   ├── webserver/
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   ├── templates/
│   │   └── vars/main.yml
│   └── database/
├── playbooks/
│   ├── site.yml
│   └── webserver.yml
└── inventory/
    ├── production
    └── staging
```

#### 2. Roles gebruiken
```bash
# Role aanmaken
ansible-galaxy init roles/webserver

# Role structuur
roles/webserver/
├── tasks/main.yml       # Hoofdtaken
├── handlers/main.yml    # Handlers
├── templates/          # Jinja2 templates
├── files/             # Statische bestanden
├── vars/main.yml      # Role variabelen
├── defaults/main.yml  # Default waarden
└── meta/main.yml      # Role metadata
```

#### 3. Vault voor gevoelige data
```bash
# Encrypted file aanmaken
ansible-vault create secret.yml

# Playbook met vault
ansible-playbook -i hosts playbook.yml --ask-vault-pass

# Vault password file
ansible-playbook -i hosts playbook.yml --vault-password-file ~/.vault_pass
```

---

## Deel 2: Terraform/OpenTofu - Infrastructure Provisioning

### Wat is Terraform?

Terraform is een open-source Infrastructure as Code tool van HashiCorp voor:
- **Infrastructure provisioning**: Cloud resources aanmaken
- **Multi-cloud**: Werkt met AWS, Azure, GCP, VMware, etc.
- **State management**: Houdt bij wat bestaat
- **Dependency management**: Begrijpt resource afhankelijkheden

### OpenTofu: Open Source Alternatief

OpenTofu is een community-driven fork van Terraform:
- **100% compatibel** met Terraform
- **Open source** under MPL-2.0 license
- **Community governance**
- **Actieve development**

### Declaratief vs Imperatief: Het Fundamentele Verschil

#### **Terraform: Declaratieve Benadering**

Terraform gebruikt een **declaratieve** programmeertaal (HCL - HashiCorp Configuration Language). Dit betekent dat je **beschrijft WAT je wilt**, niet HOE je het wilt bereiken.

```hcl
# Declaratief: "Ik wil 3 web servers"
resource "google_compute_instance" "web" {
  count        = 3
  name         = "web-server-${count.index}"
  machine_type = "f1-micro"
  
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
}
```

**Kenmerken van declaratieve taal:**
- ✅ **Gewenste eindtoestand**: Je beschrijft hoe de infrastructuur eruit moet zien
- ✅ **Idempotent**: Meerdere keren uitvoeren geeft hetzelfde resultaat
- ✅ **State-aware**: Terraform weet wat er al bestaat
- ✅ **Dependency resolution**: Automatische volgorde van resource creation
- ✅ **Drift detection**: Kan wijzigingen buiten Terraform detecteren

#### **Ansible: Imperatieve Benadering**

Ansible gebruikt een **imperatieve** benadering via YAML playbooks. Je beschrijft **HOE je stappen uitvoert** om tot het gewenste resultaat te komen.

```yaml
# Imperatief: "Voer deze stappen uit"
- name: Install and configure web servers
  hosts: all
  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        
    - name: Install nginx
      apt:
        name: nginx
        state: present
        
    - name: Start nginx service
      systemd:
        name: nginx
        state: started
        enabled: yes
        
    - name: Copy configuration file
      copy:
        src: nginx.conf
        dest: /etc/nginx/nginx.conf
      notify: restart nginx
      
  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
```

**Kenmerken van imperatieve benadering:**
- ✅ **Stap-voor-stap**: Duidelijke volgorde van acties
- ✅ **Flexibiliteit**: Conditie logica en loops
- ✅ **Fijnmazige controle**: Exacte controle over elk detail
- ✅ **Geschikt voor configuratie**: Perfect voor software instellingen
- ⚠️ **Volgorde belangrijk**: Stappen moeten in juiste volgorde uitgevoerd worden

#### **Praktisch Verschil: Server Creation**

**Terraform (Declaratief):**
```hcl
# Je zegt: "Ik wil 2 servers met deze specificaties"
resource "google_compute_instance" "app" {
  count = 2
  name  = "app-server-${count.index}"
  # ... configuratie
}

# Terraform bepaalt automatisch:
# - Of servers al bestaan
# - Welke moeten aangemaakt worden
# - In welke volgorde (dependencies)
# - Wat moet gewijzigd worden bij updates
```

**Ansible (Imperatief):**
```yaml
# Je zegt: "Voer deze acties uit op deze servers"
- name: Configure application servers
  hosts: app_servers
  tasks:
    - name: Check if application is installed
      stat:
        path: /opt/myapp
      register: app_installed
      
    - name: Download application
      get_url:
        url: "{{ app_download_url }}"
        dest: /tmp/app.tar.gz
      when: not app_installed.stat.exists
      
    - name: Extract application
      unarchive:
        src: /tmp/app.tar.gz
        dest: /opt/
      when: not app_installed.stat.exists
```

#### **Waarom Beide Benaderingen Waardevol Zijn**

| Aspect | Terraform (Declaratief) | Ansible (Imperatief) |
|--------|-------------------------|----------------------|
| **Best voor** | Infrastructure provisioning | Configuration management |
| **Mindset** | "Wat wil ik hebben?" | "Hoe ga ik het doen?" |
| **State** | Houdt state bij | Stateless (meestal) |
| **Dependencies** | Automatisch berekend | Handmatig gedefinieerd |
| **Updates** | Plan → Apply workflow | Playbook execution |
| **Rollback** | Via state management | Via reverse playbooks |
| **Learning curve** | Steiler voor beginners | Meer intuïtief |

#### **Wanneer Welke Benadering?**

**Gebruik Terraform (Declaratief) voor:**
- 🏗️ Infrastructure provisioning (VMs, netwerken, storage)
- 🔄 Lifecycle management van resources
- 🌐 Multi-cloud deployments
- 📊 Infrastructure die vaak wijzigt
- 🎯 Wanneer je wilt beschrijven "wat je wilt"

**Gebruik Ansible (Imperatief) voor:**
- ⚙️ Software configuratie en deployment
- 🔧 Complex multi-step procedures
- 🎭 Orchestration van bestaande systemen
- 📝 Wanneer je exacte controle over stappen nodig hebt
- 🔄 Wanneer je "hoe je het doet" belangrijk is

#### **Best Practice: Combinatie van Beide**

```bash
# 1. Declaratief: Maak infrastructuur met Terraform
tofu apply

# 2. Imperatief: Configureer servers met Ansible  
ansible-playbook site.yml
```

Dit combineert de kracht van beide benaderingen voor complete automation workflows!

### Terraform/OpenTofu Installatie

```bash
# OpenTofu installatie (aanbevolen)
# Ubuntu/Debian
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
sudo ./install-opentofu.sh

# macOS
brew install opentofu

# Verificatie
tofu version

# Terraform installatie (alternatief)
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Terraform/OpenTofu Workflow

```
1. WRITE → 2. PLAN → 3. APPLY → 4. DESTROY
   ↓         ↓         ↓         ↓
  .tf files  tofu plan tofu apply tofu destroy
```

#### 1. **Write**: Infrastructure definiëren
```hcl
# main.tf
resource "google_compute_instance" "web" {
  name         = "web-server"
  machine_type = "f1-micro"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
}
```

#### 2. **Plan**: Wijzigingen vooruitkijken
```bash
tofu plan
# Shows: 1 to add, 0 to change, 0 to destroy
```

#### 3. **Apply**: Wijzigingen uitvoeren
```bash
tofu apply
# Creates the actual infrastructure
```

#### 4. **Destroy**: Infrastructuur opruimen

**⚠️ KRITIEK: Waarom NOOIT handmatig verwijderen in cloud dashboards!**

**❌ Verkeerde manier - Handmatig verwijderen:**
```bash
# DOE DIT NOOIT:
# - Ga naar GCP Console
# - Verwijder VM instances handmatig
# - Verwijder VPC handmatig  
# - Verwijder firewall rules handmatig
```

**Problemen met handmatig verwijderen:**
1. **State drift**: Terraform state klopt niet meer met realiteit
2. **Orphaned resources**: Vergeten resources blijven bestaan → kosten geld
3. **Dependency issues**: Resources zijn vaak afhankelijk van elkaar
4. **No rollback**: Geen manier om terug te gaan
5. **Team confusion**: Anderen weten niet wat er gewijzigd is
6. **Lost tracking**: Geen audit trail van wijzigingen

**✅ Juiste manier - Terraform destroy:**
```bash
# Plan de destruction (veiligheidscheck)
tofu plan -destroy

# Output toont wat er verwijderd wordt:
# Plan: 0 to add, 0 to change, 5 to destroy.
#
# Changes to Outputs:
#   - ip = "34.78.123.45" -> null
#
# Do you want to perform these actions?

# Voer destroy uit
tofu destroy

# Bevestig met: yes
```

**Waarom Terraform destroy beter is:**
- ✅ **Intelligente volgorde**: Verwijdert resources in juiste volgorde (reverse dependencies)
- ✅ **State synchronisatie**: Houdt state file bij
- ✅ **Rollback mogelijkheid**: Kan altijd opnieuw tofu apply doen
- ✅ **Audit trail**: Alle wijzigingen zijn gedocumenteerd
- ✅ **Team-friendly**: Iedereen kan zien wat er gebeurd is
- ✅ **Kostenbesparing**: Geen vergeten resources

#### **Gedetailleerd Destroy Proces**

**1. Destroy planning (veilig):**
```bash
# Bekijk wat er vernietigd wordt zonder het te doen
tofu plan -destroy

# Output voorbeeld:
# Terraform will perform the following actions:
#
#   # google_compute_firewall.ssh-server will be destroyed
#   - resource "google_compute_firewall" "ssh-server" {
#       - name = "default-allow-ssh-terraform" -> null
#       # ... more details
#     }
#
#   # google_compute_instance.vm_instance will be destroyed  
#   - resource "google_compute_instance" "vm_instance" {
#       - name = "opentofu-instance" -> null
#       # ... more details
#     }
#
# Plan: 0 to add, 0 to change, 4 to destroy.
```

**2. Selective destroy (specifieke resources):**
```bash
# Verwijder alleen specifieke resource
tofu destroy -target=google_compute_instance.vm_instance

# Verwijder meerdere specifieke resources
tofu destroy -target=google_compute_instance.vm_instance -target=google_compute_firewall.ssh-server
```

**3. Force destroy (zonder confirmatie - GEVAARLIJK):**
```bash
# Automatisch destroy zonder "yes" prompt
tofu destroy -auto-approve

# ⚠️ ALLEEN GEBRUIKEN IN AUTOMATION/CI/CD!
# NOOIT HANDMATIG IN PRODUCTIE!
```

**4. Destroy met variable files:**
```bash
# Als je custom tfvars gebruikt
tofu destroy -var-file="production.tfvars"

# Met specifieke variables
tofu destroy -var="environment=staging"
```

#### **Best Practices voor Resource Cleanup**

**1. Altijd plan eerst:**
```bash
# Workflow voor veilige cleanup
tofu plan -destroy              # 1. Bekijk wat er gebeurt
tofu destroy                    # 2. Voer uit na review
```

**2. State backup voor destroy:**
```bash
# Backup state voor grote destroys
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
tofu destroy
```

**3. Environment-specific destroy:**
```bash
# Per environment
tofu workspace select staging
tofu destroy

tofu workspace select production  
tofu plan -destroy  # EXTRA VOORZICHTIG IN PRODUCTIE!
```

**4. Protect kritieke resources:**
```hcl
# In je .tf files - voorkom accidental destroy
resource "google_compute_instance" "critical_database" {
  name = "prod-database"
  
  # Voorkom destroy via Terraform
  lifecycle {
    prevent_destroy = true
  }
}
```

**5. Gradual destroy voor complexe setups:**
```bash
# Stap-voor-stap destroy van grote infrastructuur
tofu destroy -target=google_compute_instance.web_servers
tofu destroy -target=google_compute_instance.app_servers  
tofu destroy -target=google_sql_database_instance.db
tofu destroy  # Rest van infrastructure
```

#### **Troubleshooting Destroy Issues**

**1. Resource dependencies:**
```bash
# Als destroy faalt door dependencies
tofu destroy -target=dependent_resource
tofu destroy  # Dan de rest
```

**2. External changes (drift):**
```bash
# Als resources handmatig gewijzigd zijn
tofu refresh    # Update state met echte situatie
tofu destroy    # Dan destroy
```

**3. Stuck resources:**
```bash
# Als resources niet kunnen worden verwijderd
tofu state list                                    # Bekijk state
tofu state rm google_compute_instance.stuck       # Remove van state
# Handmatig opruimen in cloud console (als laatste redmiddel)
```

**4. Import vergeten resources:**
```bash
# Als je vergeten resources hebt
tofu import google_compute_instance.existing projects/PROJECT/zones/ZONE/instances/INSTANCE
tofu destroy  # Dan kan destroy ze vinden
```

#### **Cost Monitoring & Cleanup Automation**

**1. Automated cleanup scripts:**
```bash
#!/bin/bash
# cleanup-dev-environment.sh

echo "Cleaning up development environment..."
cd terraform/environments/dev
tofu destroy -auto-approve
echo "Dev environment cleaned up!"
```

**2. Scheduled cleanup (cron):**
```bash
# Automatisch dev environments opruimen elke vrijdag
0 18 * * 5 /home/user/scripts/cleanup-dev-environment.sh
```

**3. Cost alerts integratie:**
```hcl
# Monitoring resource om kosten bij te houden
resource "google_billing_budget" "dev_budget" {
  billing_account = var.billing_account
  display_name    = "Dev Environment Budget"
  
  budget_filter {
    projects = ["projects/${var.project_id}"]
  }
  
  amount {
    specified_amount {
      currency_code = "EUR"
      units         = "100"  # 100 EUR budget
    }
  }
}
```

**🎯 Onthoud: Terraform destroy is je veiligheidsnet tegen kostbare vergissingen en orphaned resources!**

### HCL (HashiCorp Configuration Language)

#### Basis syntax
```hcl
# Comments start with #

# Variables
variable "instance_name" {
  description = "Name of the instance"
  type        = string
  default     = "my-instance"
}

# Resources
resource "resource_type" "resource_name" {
  argument1 = "value1"
  argument2 = var.instance_name
  
  nested_block {
    nested_argument = "nested_value"
  }
}

# Outputs
output "instance_ip" {
  value = resource.resource_type.resource_name.public_ip
}
```

### Praktisch voorbeeld: Google Cloud Platform

#### Basis GCP setup

```hcl
# 5-iac-files/opentofu/demoGCE/main.tf
variable "gce_ssh_user" {
  description = "SSH user for GCE instances"
}

variable "gce_ssh_pub_key_file" {
  description = "Path to SSH public key file"
}

variable "gcp_project" {
  description = "GCP Project ID"
}

variable "gcp_region" {
  description = "GCP Region"
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  default     = "us-central1-a"
}

variable "gcp_key_file" {
  description = "Path to GCP service account key file"
}

# Provider configuratie
provider "google" {
  credentials = file(var.gcp_key_file)
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
}

# Static IP address
resource "google_compute_address" "static" {
  name = "ipv4-address"
}

# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = "vpc-network"
  auto_create_subnetworks = "true"
}

# Firewall rule
resource "google_compute_firewall" "ssh-server" {
  name    = "default-allow-ssh-terraform"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-server"]
}

# VM Instance
resource "google_compute_instance" "vm_instance" {
  name         = "opentofu-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-focal-v20210415"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  tags = ["ssh-server"]
}

# Output values
output "ip" {
  description = "Public IP address of the instance"
  value       = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}

output "instance_name" {
  description = "Name of the instance"
  value       = google_compute_instance.vm_instance.name
}
```

#### Variables file

```hcl
# terraform.tfvars (create this file locally)
gce_ssh_user         = "ubuntu"
gce_ssh_pub_key_file = "~/.ssh/id_rsa.pub"
gcp_project          = "my-gcp-project"
gcp_region           = "europe-west1"
gcp_zone             = "europe-west1-b"
gcp_key_file         = "path/to/service-account-key.json"
```

### Terraform/OpenTofu Commando's

```bash
# Project initialiseren
tofu init

# Configuratie valideren
tofu validate

# Wijzigingen plannen
tofu plan

# Plan opslaan
tofu plan -out=plan.tfplan

# Plan uitvoeren
tofu apply

# Specifiek plan uitvoeren
tofu apply plan.tfplan

# Current state bekijken
tofu show

# State list
tofu state list

# Resource importeren
tofu import google_compute_instance.web my-instance

# Infrastructuur vernietigen
tofu destroy

# Plan destroy (safety check)
tofu plan -destroy

# Destroy specific resources
tofu destroy -target=google_compute_instance.vm_instance

# Auto-approve destroy (automation only!)
tofu destroy -auto-approve

# Destroy with variables
tofu destroy -var-file="staging.tfvars"

# Specifieke resource targeten
tofu apply -target=google_compute_instance.vm_instance

# Workspace management
tofu workspace new production
tofu workspace select staging
tofu workspace list
```

### State Management

#### Terraform State file
```json
{
  "version": 4,
  "terraform_version": "1.0.0",
  "serial": 1,
  "lineage": "uuid",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "google_compute_instance",
      "name": "vm_instance",
      "instances": [...]
    }
  ]
}
```

#### Remote State (Productie)
```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"
    prefix = "terraform/state"
  }
}

# Alternative: S3 backend
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"
  }
}
```

### Geavanceerde Terraform Concepten

#### 1. Modules
```hcl
# modules/webserver/main.tf
variable "instance_count" {
  description = "Number of instances"
  default     = 1
}

resource "google_compute_instance" "web" {
  count        = var.instance_count
  name         = "web-${count.index}"
  machine_type = "f1-micro"
  # ... rest of configuration
}

# main.tf (using the module)
module "webserver" {
  source         = "./modules/webserver"
  instance_count = 3
}
```

#### 2. Data Sources
```hcl
# Existing resource lookup
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "vm" {
  # Use data source
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }
}
```

#### 3. Provisioners
```hcl
resource "google_compute_instance" "web" {
  # ... instance configuration

  # File provisioner
  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
    
    connection {
      type     = "ssh"
      user     = var.ssh_user
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }

  # Remote exec provisioner
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh",
    ]
    
    connection {
      type     = "ssh"
      user     = var.ssh_user
      host     = self.network_interface.0.access_config.0.nat_ip
    }
  }
}
```

#### 4. Conditionals en Functions
```hcl
# Conditional resources
resource "google_compute_instance" "web" {
  count = var.environment == "production" ? 3 : 1
  name  = "web-${count.index}"
  # ...
}

# Functions
locals {
  instance_names = [for i in range(var.instance_count) : "web-${i}"]
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
```

---

## Deel 3: Ansible + Terraform Integratie

### Waarom beide tools combineren?

1. **Terraform**: Maakt infrastructuur aan (VMs, netwerken, load balancers)
2. **Ansible**: Configureert de infrastructuur (software, services, users)

### Workflow voorbeeld

#### Stap 1: Infrastructuur met Terraform
```hcl
# main.tf - Create multiple VMs
resource "google_compute_instance" "web_servers" {
  count        = 3
  name         = "web-server-${count.index}"
  machine_type = "f1-micro"
  
  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
  
  tags = ["web-server"]
}

# Output IP addresses for Ansible
output "web_server_ips" {
  value = google_compute_instance.web_servers[*].network_interface.0.access_config.0.nat_ip
}
```

#### Stap 2: Dynamic Inventory voor Ansible
```bash
# Get IPs from Terraform output
tofu output -json web_server_ips | jq -r '.[]' > ansible_hosts.txt

# Or use Terraform provider for Ansible
```

#### Stap 3: Configuratie met Ansible
```yaml
# playbook.yml
---
- name: Configure web servers
  hosts: all
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        
    - name: Start nginx
      systemd:
        name: nginx
        state: started
        enabled: yes
```

#### Stap 4: Uitvoering
```bash
# 1. Create infrastructure
tofu apply

# 2. Configure with Ansible
ansible-playbook -i ansible_hosts.txt playbook.yml
```

### Terraform Ansible Provider

```hcl
# Using Ansible provider in Terraform
resource "ansible_playbook" "configure_servers" {
  playbook   = "playbook.yml"
  name       = google_compute_instance.web_servers[*].network_interface.0.access_config.0.nat_ip
  
  depends_on = [google_compute_instance.web_servers]
}
```

---

## Deel 4: Hands-on Oefeningen

### Oefening 1: Ansible Basics

#### Setup
```bash
cd 5-iac-files/ansible

# Test connectivity
ansible all -i hosts -m ping

# Check OS version
ansible mycloudvms -i hosts -a "cat /etc/os-release"
```

#### Taken
1. **Systeem updates uitvoeren**
```bash
ansible all -i hosts -m apt -a "update_cache=yes upgrade=dist" --become
```

2. **Packages installeren**
```bash
ansible all -i hosts -m apt -a "name=htop,curl,git state=present" --become
```

3. **User aanmaken**
```bash
ansible all -i hosts -m user -a "name=student shell=/bin/bash groups=sudo" --become
```

4. **File kopiëren**
```bash
ansible all -i hosts -m copy -a "content='Hello Ansible!' dest=/tmp/hello.txt"
```

### Oefening 2: Ansible Playbook

Maak een playbook voor LAMP stack installatie:

```yaml
# lamp-stack.yml
---
- name: LAMP Stack Installation
  hosts: ubuntu-servers
  become: yes
  vars:
    mysql_root_password: "secure123"
    
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        
    - name: Install LAMP packages
      apt:
        name:
          - apache2
          - mysql-server
          - php
          - php-mysql
          - libapache2-mod-php
        state: present
        
    - name: Start Apache
      systemd:
        name: apache2
        state: started
        enabled: yes
        
    - name: Start MySQL
      systemd:
        name: mysql
        state: started
        enabled: yes
        
    - name: Create test PHP file
      copy:
        content: |
          <?php
          phpinfo();
          ?>
        dest: /var/www/html/info.php
        
    - name: Set MySQL root password
      mysql_user:
        name: root
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/run/mysqld/mysqld.sock
```

### Oefening 3: Terraform GCP Setup

#### Voorbereiding
1. **GCP Account en Project**
2. **Service Account Key** (JSON file)
3. **SSH Key Pair**

```bash
# SSH key genereren
ssh-keygen -t rsa -b 4096 -f ~/.ssh/gcp_key
```

#### Terraform configuratie
```bash
cd 5-iac-files/opentofu/demoGCE

# Variabelen file aanmaken
cat > terraform.tfvars << EOF
gce_ssh_user         = "ubuntu"
gce_ssh_pub_key_file = "~/.ssh/gcp_key.pub"
gcp_project          = "your-project-id"
gcp_region           = "europe-west1"
gcp_zone             = "europe-west1-b"
gcp_key_file         = "path/to/service-account.json"
EOF

# Initialiseren
tofu init

# Plan
tofu plan

# Apply
tofu apply
```

### Oefening 4: Multi-tier Applicatie

#### Terraform: Infrastructuur
```hcl
# multi-tier.tf
variable "instance_count" {
  default = {
    web = 2
    app = 2
    db  = 1
  }
}

# Web tier
resource "google_compute_instance" "web_tier" {
  count        = var.instance_count.web
  name         = "web-${count.index}"
  machine_type = "f1-micro"
  tags         = ["web-tier", "http-server"]
  
  # ... configuration
}

# App tier
resource "google_compute_instance" "app_tier" {
  count        = var.instance_count.app
  name         = "app-${count.index}"
  machine_type = "f1-micro"
  tags         = ["app-tier"]
  
  # ... configuration
}

# Database tier
resource "google_compute_instance" "db_tier" {
  count        = var.instance_count.db
  name         = "db-${count.index}"
  machine_type = "n1-standard-1"
  tags         = ["db-tier"]
  
  # ... configuration
}

# Load balancer
resource "google_compute_http_health_check" "web_health" {
  name = "web-health-check"
}

resource "google_compute_target_pool" "web_pool" {
  name      = "web-pool"
  instances = google_compute_instance.web_tier[*].self_link
  
  health_checks = [
    google_compute_http_health_check.web_health.name,
  ]
}
```

#### Ansible: Configuratie per tier
```yaml
# site.yml
---
- import_playbook: web-tier.yml
- import_playbook: app-tier.yml
- import_playbook: db-tier.yml

# web-tier.yml
---
- name: Configure Web Tier
  hosts: web_tier
  become: yes
  roles:
    - nginx
    - ssl_certificates

# app-tier.yml  
---
- name: Configure App Tier
  hosts: app_tier
  become: yes
  roles:
    - nodejs
    - application_code

# db-tier.yml
---
- name: Configure Database Tier
  hosts: db_tier
  become: yes
  roles:
    - mysql
    - database_setup
```

### Oefening 5: Declaratief vs Imperatief - Hands-on Vergelijking

Deze oefening demonstreert het verschil tussen declaratieve en imperatieve benaderingen met een praktische server setup.

#### **Scenario: Web Server met Database Setup**

We gaan een web server met database opzetten op **twee manieren** om het verschil te ervaren.

#### **Deel A: Terraform (Declaratief) - "WAT je wilt"**

```hcl
# infrastructure.tf
variable "server_count" {
  description = "Number of web servers"
  default     = 2
}

# Declaratief: "Ik wil 2 web servers met deze specificaties"
resource "google_compute_instance" "web_servers" {
  count        = var.server_count
  name         = "web-server-${count.index + 1}"
  machine_type = "f1-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  tags = ["web-server", "http-server"]

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}

# Declaratief: "Ik wil een database server"
resource "google_compute_instance" "database" {
  name         = "database-server"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 50  # Bigger disk for database
    }
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    access_config {}
  }

  tags = ["database-server"]
}

# Declaratief: "Ik wil een VPC netwerk"
resource "google_compute_network" "vpc" {
  name                    = "web-app-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "web-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west1"
  network       = google_compute_network.vpc.self_link
}

# Terraform figureert automatisch uit:
# - Welke volgorde (VPC → Subnet → VMs)
# - Welke dependencies
# - Wat al bestaat vs wat nieuw is
```

**Terraform Uitvoering:**
```bash
# Terraform kijkt naar gewenste state vs huidige state
tofu plan
# Plan: 4 to add, 0 to change, 0 to destroy

tofu apply
# Terraform maakt automatisch:
# 1. VPC network
# 2. Subnet (hangt af van VPC)
# 3. Web servers (hangen af van subnet)
# 4. Database server

# Als je later meer servers wilt:
# Wijzig variable server_count = 4
tofu plan
# Plan: 2 to add, 0 to change, 0 to destroy (alleen nieuwe servers!)

tofu apply
# Terraform maakt alleen de 2 nieuwe servers aan
```

#### **Deel B: Ansible (Imperatief) - "HOE je het doet"**

```yaml
# setup-infrastructure.yml
---
- name: Setup Complete Web Application Infrastructure
  hosts: localhost
  gather_facts: no
  vars:
    servers_to_create:
      - { name: "web-server-1", type: "web" }
      - { name: "web-server-2", type: "web" }
      - { name: "database-server", type: "db" }

  tasks:
    # Stap 1: Check if VPC exists
    - name: Check if VPC network exists
      google.cloud.gcp_compute_network_info:
        filters:
          - name = "web-app-network"
      register: vpc_result

    # Stap 2: Create VPC if it doesn't exist
    - name: Create VPC network
      google.cloud.gcp_compute_network:
        name: "web-app-network"
        auto_create_subnetworks: false
        state: present
      when: vpc_result.resources | length == 0

    # Stap 3: Check if subnet exists
    - name: Check if subnet exists
      google.cloud.gcp_compute_subnetwork_info:
        region: "europe-west1"
        filters:
          - name = "web-subnet"
      register: subnet_result

    # Stap 4: Create subnet if it doesn't exist
    - name: Create subnet
      google.cloud.gcp_compute_subnetwork:
        name: "web-subnet"
        ip_cidr_range: "10.0.1.0/24"
        region: "europe-west1"
        network:
          selfLink: "projects/{{ gcp_project }}/global/networks/web-app-network"
        state: present
      when: subnet_result.resources | length == 0

    # Stap 5: Check which servers already exist
    - name: Get existing instances
      google.cloud.gcp_compute_instance_info:
        zone: "europe-west1-b"
      register: existing_instances

    # Stap 6: Create servers that don't exist yet
    - name: Create web and database servers
      google.cloud.gcp_compute_instance:
        name: "{{ item.name }}"
        machine_type: "{{ 'f1-micro' if item.type == 'web' else 'n1-standard-1' }}"
        zone: "europe-west1-b"
        disks:
          - auto_delete: true
            boot: true
            initialize_params:
              source_image: "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
              disk_size_gb: "{{ 10 if item.type == 'web' else 50 }}"
        network_interfaces:
          - network:
              selfLink: "projects/{{ gcp_project }}/global/networks/web-app-network"
            subnetwork:
              selfLink: "projects/{{ gcp_project }}/regions/europe-west1/subnetworks/web-subnet"
            access_configs:
              - name: External NAT
                type: ONE_TO_ONE_NAT
        tags:
          items:
            - "{{ item.type }}-server"
            - "{{ 'http-server' if item.type == 'web' else 'database-server' }}"
        state: present
      loop: "{{ servers_to_create }}"
      when: item.name not in (existing_instances.resources | map(attribute='name') | list)

    # Stap 7: Configure web servers after they're created
    - name: Wait for SSH to be available
      wait_for:
        port: 22
        host: "{{ hostvars[item.name]['ansible_host'] }}"
        delay: 30
        timeout: 300
      loop: "{{ servers_to_create }}"
      when: item.type == 'web'

    # Stap 8: Install web server software
    - name: Install nginx on web servers
      apt:
        name: nginx
        state: present
        update_cache: yes
      delegate_to: "{{ item.name }}"
      become: yes
      loop: "{{ servers_to_create }}"
      when: item.type == 'web'

    # Stap 9: Configure database server
    - name: Install MySQL on database server
      apt:
        name: mysql-server
        state: present
        update_cache: yes
      delegate_to: "database-server"
      become: yes

# Ansible vereist dat je elke stap expliciet beschrijft
```

**Ansible Uitvoering:**
```bash
# Ansible voert elke stap uit in volgorde
ansible-playbook setup-infrastructure.yml

# Als je later meer servers wilt:
# Wijzig de servers_to_create lijst
# Ansible controleert weer alle stappen
ansible-playbook setup-infrastructure.yml
# Alle checks worden opnieuw uitgevoerd, alleen nieuwe servers worden toegevoegd
```

#### **Deel C: Cleanup Vergelijking**

**Terraform Cleanup (Declaratief):**
```bash
# Terraform weet exact wat het heeft gemaakt
tofu plan -destroy
# Plan: 0 to add, 0 to change, 4 to destroy.
#   - google_compute_instance.database
#   - google_compute_instance.web_servers[0]
#   - google_compute_instance.web_servers[1]
#   - google_compute_network.vpc

tofu destroy
# Verwijdert alles in reverse dependency volgorde:
# 1. VMs eerst (afhankelijk van subnet)
# 2. Subnet (afhankelijk van VPC)
# 3. VPC als laatste
```

**Ansible Cleanup (Imperatief):**
```yaml
# cleanup-infrastructure.yml
---
- name: Cleanup Complete Infrastructure
  hosts: localhost
  tasks:
    # Stap 1: Stop all services first
    - name: Stop nginx on web servers
      systemd:
        name: nginx
        state: stopped
      delegate_to: "{{ item }}"
      become: yes
      loop:
        - web-server-1
        - web-server-2
      ignore_errors: yes

    # Stap 2: Delete instances in correct order
    - name: Delete web servers first
      google.cloud.gcp_compute_instance:
        name: "{{ item }}"
        zone: "europe-west1-b"
        state: absent
      loop:
        - web-server-1
        - web-server-2

    # Stap 3: Delete database server
    - name: Delete database server
      google.cloud.gcp_compute_instance:
        name: "database-server"
        zone: "europe-west1-b"
        state: absent

    # Stap 4: Wait for instances to be fully deleted
    - name: Wait for instances to be deleted
      pause:
        seconds: 30

    # Stap 5: Delete subnet
    - name: Delete subnet
      google.cloud.gcp_compute_subnetwork:
        name: "web-subnet"
        region: "europe-west1"
        state: absent

    # Stap 6: Delete VPC
    - name: Delete VPC network
      google.cloud.gcp_compute_network:
        name: "web-app-network"
        state: absent

# Je moet handmatig de juiste volgorde bepalen!
```

#### **Praktische Opdrachten**

**1. Terraform Oefening:**
```bash
# Maak de infrastructuur
cd terraform-declarative/
tofu init
tofu plan
tofu apply

# Schaal op (wijzig server_count naar 4)
tofu plan  # Bekijk wat er wijzigt
tofu apply

# Schaal af (wijzig server_count naar 1)
tofu plan  # Bekijk wat er verwijderd wordt
tofu apply

# Volledige cleanup
tofu destroy
```

**2. Ansible Oefening:**
```bash
# Maak de infrastructuur
cd ansible-imperative/
ansible-playbook setup-infrastructure.yml

# Voeg servers toe (wijzig servers_to_create lijst)
ansible-playbook setup-infrastructure.yml

# Cleanup
ansible-playbook cleanup-infrastructure.yml
```

**3. Vergelijkings-analyse:**

| Aspect | Terraform (Declaratief) | Ansible (Imperatief) |
|--------|--------------------------|----------------------|
| **Code lengte** | ±50 regels | ±150+ regels |
| **Dependency management** | Automatisch | Handmatig in juiste volgorde |
| **State awareness** | Weet wat bestaat | Moet elke keer checken |
| **Scaling up** | Wijzig getal → apply | Wijzig lijst → veel checks |
| **Scaling down** | Wijzig getal → apply | Expliciete delete stappen |
| **Cleanup** | 1 commando | Multi-step playbook |
| **Error handling** | Built-in rollback | Handmatige error handling |

#### **Leeruitkomsten**

Na deze oefening begrijp je:
- ✅ **Waarom declaratief efficiënter is** voor infrastructuur
- ✅ **Hoe Terraform dependencies automatisch oplost**
- ✅ **Waarom cleanup met Terraform veiliger is**
- ✅ **Wanneer imperative benadering nuttig is**
- ✅ **Hoe beide tools complementair zijn**

**🎯 Conclusie: Terraform voor "WAT", Ansible voor "HOE"!**

---

## Deel 5: Best Practices en Productie

### Terraform Best Practices

#### 1. **Project structuur**
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── production/
├── modules/
│   ├── networking/
│   ├── compute/
│   └── database/
└── policies/
    └── security.rego
```

#### 2. **State management**
```hcl
# Remote state
terraform {
  backend "gcs" {
    bucket = "company-terraform-state"
    prefix = "environments/production"
  }
  
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
```

#### 3. **Resource naming**
```hcl
locals {
  name_prefix = "${var.environment}-${var.project}"
  
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Team        = var.team
  }
}

resource "google_compute_instance" "web" {
  name = "${local.name_prefix}-web-${count.index}"
  
  labels = local.common_tags
}
```

#### 4. **Security**
```hcl
# Variables for sensitive data
variable "database_password" {
  description = "Database root password"
  type        = string
  sensitive   = true
}

# Use data sources for existing resources
data "google_secret_manager_secret_version" "db_password" {
  secret = "database-password"
}
```

### Ansible Best Practices

#### 1. **Role-based structuur**
```
ansible/
├── group_vars/
│   ├── all.yml
│   ├── web.yml
│   └── db.yml
├── host_vars/
├── inventories/
│   ├── production/
│   └── staging/
├── roles/
│   ├── common/
│   ├── webserver/
│   └── database/
├── playbooks/
│   ├── site.yml
│   └── deploy.yml
└── ansible.cfg
```

#### 2. **Security met Vault**
```bash
# Secrets encrypten
ansible-vault encrypt group_vars/all/vault.yml

# Playbook met vault
ansible-playbook site.yml --ask-vault-pass
```

#### 3. **Testing**
```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: ubuntu:20.04
provisioner:
  name: ansible
verifier:
  name: ansible
```

#### 4. **CI/CD Integratie**
```yaml
# .github/workflows/ansible.yml
name: Ansible CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run ansible-lint
        run: ansible-lint
      - name: Run molecule test
        run: molecule test
```

### Monitoring en Logging

#### 1. **Terraform State monitoring**
```bash
# State drift detection
terraform plan -detailed-exitcode

# State backup
terraform state pull > backup-$(date +%Y%m%d).tfstate
```

#### 2. **Ansible logging**
```ini
# ansible.cfg
[defaults]
log_path = /var/log/ansible.log
callback_whitelist = profile_tasks, timer

[callback_profile_tasks]
task_output_limit = 20
```

#### 3. **Infrastructure monitoring**
```hcl
# Monitoring resources
resource "google_monitoring_uptime_check_config" "web_check" {
  display_name = "Web server uptime check"
  timeout      = "10s"
  
  http_check {
    path = "/"
    port = "80"
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      host       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
      project_id = var.gcp_project
    }
  }
}
```

---

## Troubleshooting en Debug

### Terraform Debugging

#### 1. **Logging levels**
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
tofu apply
```

#### 2. **State issues**
```bash
# State list
tofu state list

# State show
tofu state show google_compute_instance.web

# Remove from state (dangerous!)
tofu state rm google_compute_instance.web

# Import existing resource
tofu import google_compute_instance.web projects/PROJECT/zones/ZONE/instances/INSTANCE
```

#### 3. **Graph visualization**
```bash
# Dependency graph
tofu graph | dot -Tsvg > graph.svg
```

### Ansible Debugging

#### 1. **Verbosity levels**
```bash
# Basic verbosity
ansible-playbook playbook.yml -v

# Maximum verbosity
ansible-playbook playbook.yml -vvvv

# Debug specific task
- name: Debug task
  debug:
    var: ansible_facts
```

#### 2. **Connection issues**
```bash
# Test connectivity
ansible all -m ping -vvvv

# SSH debug
ansible all -m shell -a "whoami" --ssh-extra-args="-vvv"
```

#### 3. **Facts gathering**
```bash
# Gather all facts
ansible hostname -m setup

# Specific fact
ansible hostname -m setup -a "filter=ansible_distribution*"
```

---

## Conclusie

### Samenvatting

**Infrastructure as Code transformeert IT-beheer:**

#### **Ansible (Configuration Management)**
- ✅ **Agentless**: Geen software op doelservers
- ✅ **Idempotent**: Veilig meerdere keren uitvoeren
- ✅ **YAML syntax**: Gemakkelijk leesbaar
- ✅ **Uitgebreide modules**: Voor alle configuratie taken

#### **Terraform/OpenTofu (Infrastructure Provisioning)**
- ✅ **Multi-cloud**: AWS, Azure, GCP, VMware
- ✅ **State management**: Houdt infrastructuur bij
- ✅ **Dependency resolution**: Intelligente resource volgorde
- ✅ **Plan/Apply workflow**: Veilige infrastructuur wijzigingen

#### **Samen sterker**
1. **Terraform** → Infrastructuur aanmaken
2. **Ansible** → Infrastructuur configureren
3. **Beide** → Volledig geautomatiseerde omgevingen

### Next Steps

#### **Beginner level**
1. **Practice**: Gebruik de oefeningen in `5-iac-files/`
2. **Experiment**: Probeer verschillende modules en providers
3. **Document**: Maak eigen playbooks en terraform modules

#### **Intermediate level**
1. **CI/CD**: Integreer IAC in deployment pipelines
2. **Testing**: Gebruik tools zoals Molecule en Terratest
3. **Security**: Implementeer vault en secrets management

#### **Advanced level**
1. **Multi-environment**: Dev/Staging/Production workflows
2. **Compliance**: Policy as Code met OPA/Sentinel
3. **GitOps**: Full GitOps workflows met ArgoCD/Flux

### Hantige Resources

#### **Documentatie**
- [Ansible Documentation](https://docs.ansible.com/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [OpenTofu Documentation](https://opentofu.org/docs/)

#### **Community**
- [Ansible Galaxy](https://galaxy.ansible.com/) - Roles en collections
- [Terraform Registry](https://registry.terraform.io/) - Modules en providers
- [OpenTofu Registry](https://github.com/opentofu/registry) - Open source registry

#### **Tools**
- [Ansible Lint](https://ansible-lint.readthedocs.io/) - Playbook linting
- [Terraform fmt](https://www.terraform.io/docs/commands/fmt.html) - Code formatting
- [Checkov](https://www.checkov.io/) - Security scanning

**🚀 De toekomst is Infrastructure as Code - start vandaag!**