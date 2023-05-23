# Etape 1: Premières commandes Terraform
On commence donc sur le premier tag, qui doit s'afficher comme ceci dans votre prompt: 
```
ec2-user:~/environment/terraform-aws-lab/infra ((step00-startHere)) $ 
```

## Le fichier `versions.tf` et la notion de _providers_
Tout le code HCL/Terraform va se trouver dans le dossier `infra`, qui pour le moment contient un fichier `versions.tf` avec le contenu suivant:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region              = "ca-central-1"
  shared_config_files = ["~/.aws/credentials"]
}
```
Il y a plusieurs choses intéressantes dans ce fichier. Tout d'abord la section `terraform/required_providers` contient la liste des _providers_ utilisés par notre configuration. Les providers sont des plugins utilisés par Terraform pour interagir avec un provider de cloud ou tout autre API. Dans ce lab on va utiliser 2 providers développés par HashiCorp:
- Le provider `hashicorp/aws` permet logiquement d'interagir avec les APIs d'AWS
- Le provider `hashicorp/random` ajoute des fonctionnalités de _random_ pour s'assurer que le nom de nos ressources dans AWS soient uniques

Le provider `hashicorp/aws` a sa propre section de configuration dans laquelle on précise la région qu'on veut utiliser (Canada Central) ainsi que la manière à laquelle Terraform va s'authentifier auprès d'AWS: ici on va utiliser le fichier `~/.aws/credentials` qui est déjà pré-rempli sur notre instance du service Cloud9.

Enfin on précise dans l'élément `terraform/required_version` la version de Terraform à utiliser pour appliquer notre configuration.

> Pour en savoir plus sur les providers, consultez [cette page](https://developer.hashicorp.com/terraform/language/providers) de la documentation.  
Pour comprendre la syntaxe du `required_version`, [c'est par là](https://developer.hashicorp.com/terraform/language/expressions/version-constraints).

> Un provider peut être configuré plusieurs fois avec des paramètres différents avec la fonctionnalité d'[alias](https://developer.hashicorp.com/terraform/language/providers/configuration#alias-multiple-provider-configurations). Avec AWS cela permet d'avoir des providers qui utilisent des régions ou des comptes AWS différents.

## Initialisation de Terraform
Placez-vous dans le dossier infra depuis le terminal de Cloud9 et lancez la commande `terraform init`.  
Vous obtenez l'output suivant:
```shell
ec2-user:~/environment/terraform-aws-lab/infra ((step00-startHere)) $ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 4.0"...
- Finding hashicorp/random versions matching "~> 3.0"...
- Installing hashicorp/aws v4.66.1...
- Installed hashicorp/aws v4.66.1 (signed by HashiCorp)
- Installing hashicorp/random v3.5.1...
- Installed hashicorp/random v3.5.1 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ec2-user:~/environment/terraform-aws-lab/infra ((step00-startHere)) $ 
```
Cette commande initialise l'environnement Terraform avec les actions suivantes:
- Téléchargement des providers dans le sous-dossier `.terraform`
- Création du fichier `.terraform.lock.hcl`

Les providers sont des fichiers binaires qui ne doivent pas être inclus dans le repository git.  
Par contre le fichier `.terraform.lock.hcl` doit être inclus, il contient les informations sur les versions utilisées, et permet donc que tous les utilisateurs du repository utilisent exactement les mêmes versions de providers. Ce fichier n'est jamais modifié à la main (heureusement vu son contenu 😉), mais via la commande `init` de Terraform.  

## Création d'une première ressource dans AWS

### Création du fichier `main.tf`
Toujours dans le dossier `infra` ajoutez le fichier `main.tf` avec le contenu suivant:
```hcl
resource "random_pet" "pet" {}

resource "aws_s3_bucket" "web" {
  bucket = "s3-aws-tf-lab-${random_pet.pet.id}"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.web.id
  key          = "index.html"
  source       = "../src/index.html"
  content_type = "text/html"
}
```
Ce fichier est le début de notre configuration avec les 3 ressources suivantes:
1. Le `random_pet` du provider `random` permet de générer un nom d'animal (comme le nom des conteneur docker) qu'on va utiliser dans le nom des ressources AWS pour les rendre unique (c'est juste un peu plus sympa qu'un _guid_)
2. `aws_s3_bucket` représente le futur bucket S3 dans AWS. Remarquez comme on utilise l'attribut `id` de notre `random_pet` dans le nom du bucket
3. `aws_s3_objet` permet de prendre le fichier `index.html` de notre repository pour le charger dans le bucket. On voit que le bucket est référencé par son `id` dans la propriété `bucket`

### Premier _plan_
De retour dans le terminal de Cloud9, lancez la commande `terraform plan`.  
Cette commande fondamentale permet de comparer notre _configuration_ (ce qu'il y a dans nos fichiers `.tf`) avec notre _infrastructure_ (ce qu'il y a dans AWS). Comme pour le moment notre infrastructure est vide, vous devez avoir la ligne suivante dans l'output de la commande:
```
Plan: 3 to add, 0 to change, 0 to destroy.
```
Ainsi que le détail des 3 ressources que Terraform prévoit d'ajouter.

### Premier _apply_
Deuxième commande fondamentale à lancer dès maintenant: `terraform apply` (tapez `yes` quand on vous le demande pour valider les changements).  
Cette commande applique les modifications du _plan_ et créé donc les ressources dans AWS comme on le voit dans cette ligne de l'output:
```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
``` 
Le bucket est maintenant visible depuis la [console AWS](https://s3.console.aws.amazon.com/s3/buckets?region=ca-central-1). 
Vous pouvez également cliquer sur le fichier `index.html`, puis sur le bouton _Ouvrir_ ici:
![Bouton ouvrir](/docs/assets/step01-openfile.png)
Pour afficher la page web:
![Page index.html](/docs/assets/step01-webpage.png)

### Le _state_ et les _backends_
De retour dans Cloud9, dans l'explorateur de fichier vous remarquerez le fichier `terraform.tfstate` qui vient d'être créé par la commande `apply`.  
Ce fichier représente le _state_, un concept très important de Terraform. Le state est une représentation de l'ensemble des ressources, et permet à Terraform de faire le lien entre la _configuration_ et l'_infrastructure_.  
Quand Terraform effectue un `plan` ou un `apply`, il s'appuie sur le state pour déterminer les changements à effectuer, dont les suppressions de ressources, et détecter d'éventuels changement fait en dehors de Terraform (depuis la console AWS par exemple).  

> Le state est un sujet assez complexe, pour mieux le comprendre vous pouvez consulter [cette page](https://developer.hashicorp.com/terraform/language/state) de la documentation ainsi que [celle-ci](https://developer.hashicorp.com/terraform/language/state/purpose) qui explique en quoi il est nécessaire.

Prenez le temps de regarder le contenu du fichier `terraform.tfstate`: il s'agit d'une représentation en `json` des ressources qui existent dans AWS (le bucket et la page index.html) et en dehors d'AWS (le `random_pet` qui n'existe que dans le state).  

Pour le moment, stocker le state dans un fichier fonctionne pour ce lab mais dans une situation réelle posera les problèmes suivants:
- Le state contient des informations sensibles donc il faut absolument le sécuriser
- Comme il n'est bien entendu pas inclus dans le repository, cela ne permet pas de collaborer à plusieurs sur notre base de code IaC

Pour adresser cela, Terraform utilise la notion de _backends_. Un _backend_ représente l'endroit ou Terraform stocke son state. Par défaut, c'est le backend _local_ qui est utilisé (c'est notre cas).  
Il existe d'autres _backends_ qui permettent de stocker le state dans différents services de stockage comme Terraform Cloud, AWS S3 (qu'on utilisera plus loin dans ce lab), ou Azure Blob Storage.  

> Encore une fois pour aller plus loin le mieux est de se référer à la documentation officielle, qui explique [ici](https://developer.hashicorp.com/terraform/language/settings/backends/configuration) la notion de _backend_ et liste les options disponibles.

## Etape suivante
C'est la fin de cette première étape important qui présente les commandes de base. Vous pouvez passer à [l'étape suivante](/docs/step02-addModule.md) !
