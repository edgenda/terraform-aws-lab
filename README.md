# Lab Terraform avec AWS

Bienvenue dans ce lab d'introduction à Terraform dans un environnement AWS. L'objectif de ce lab est de vous faire découvrir l'outil Terraform avec une utilisation de base pendant environ une heure.  

Avant de commencer, voici quelques points et définitions avec des liens à visiter si nécessaire:
- Tout d'abord, Terraform est un outil d'Infrastructure-as-Code (IaC) créé par HashiCorp et développé en open-source
- Terraform permet de définir de l'infrastructure pour des fournisseurs de cloud publique (AWS, GCP, Azure), des solutions on-prem, et de nombreux eco-systèmes comme Kubernetes par exemple
- Terraform utilise une approche IaC _déclarative_, à l'opposé de l'approche _impérative_:
    - Dans une approche _impérative_ on définit une suite d'étapes pour arriver à un résultat, c'est le cas avec un script Bash ou PowerShell par exemple
    - L'approche _déclarative_ de Terraform décrit le résultat attendu, sans s'occuper des étapes pour l'atteindre: on dit à Terraform _"voilà ce que je veux"_, et il est sensé se débrouiller pour y arriver
- Dans ce lab (comme dans la plupart des cas avec Terraform) on va décrire notre infrastructure en utilisant le langage HCL (pour HashiCorp Configuration Language)

D'autres définitions et liens vers la documentation seront proposés en temps voulu tout au long de ce lab.

Pour faire tourner ce lab vous n'avez rien à installer, vous allez utiliser le service Cloud9 d'AWS qui permet d'interagir avec une machine de développement (éditeur de code et terminal) depuis votre navigateur web. Tous les outils dont vous avez besoin (Terraform et git en tête) y sont déjà installés.  

## Fonctionnement, objectif et lancement du lab
L'objectif de ce lab est de créer une application web simple hébergée dans un _bucket S3_, le service de stockage managé par AWS.  
Tout ce passe dans ce repository git, en plusieurs étapes. Chaque étape correspond à un _tag_ dans le repository donc vous pouvez "naviguer" entre les étapes en utilisant des commandes git.  
Pour commencer, placez-vous à la racine du repository dans le terminal de Cloud9 et exécutez la commande suivante:
```bash
. start-lab.sh
```
Cela lance un script qui effectue les actions suivantes:
- Vous positionne sur le tag de départ, vous pouvez démarrer le lab dans cette copie du repository
- Place votre terminal dans le répertoire `infra` à partir duquel toutes les commandes Terraform seront lancées
- Clone le repo une seconde fois dans le répertoire `~/environment/terraform-aws-lab-solution`. Si besoin vous pouvez utiliser ce second répertoire pour naviguer entre les tags sans interférer avec vos propres changements. 

Pour plus d'information sur l'interface de Cloud9, la documentation utilisateur est disponible [ici](https://docs.aws.amazon.com/cloud9/latest/user-guide/welcome.html). La plupart des raccourci claviers habituels fonctionnent dans le terminal (`tab` pour l'autocomplétion, `Ctrl+r` pour rechercher dans l'historique, `Ctrl+l` pour effacer, etc.). Le raccourci `Alt+s` est également bien pratique pour passer du terminal à l'éditeur de code, et inversement 😉

## A propos de la documentation de Terraform
Les concepts principaux de Terraform seront abordés tout au long de ce lab, avec des liens vers la documentation officielle.  
En travaillant avec Terraform vous serez amené à utiliser régulièrement les deux sites suivants:
1. [developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform) pour tout ce qui concerne le coeur de l'outil:
    - La partie [CLI](https://developer.hashicorp.com/terraform/cli) avec toutes les commandes
    - La partie [HCL](https://developer.hashicorp.com/terraform/language) avec tout ce qui concerne le langage (la [syntaxe](https://developer.hashicorp.com/terraform/language/syntax), les [expressions](https://developer.hashicorp.com/terraform/language/expressions), les [functions](https://developer.hashicorp.com/terraform/language/functions), etc.)
2. [registry.terraform.io](https://registry.terraform.io/) pour la documentation de chaque _provider_ (un concept expliqué dès le début du lab). Typiquement on va consulter ce site pour tout ce qui est spécifique à [AWS](https://registry.terraform.io/providers/hashicorp/aws/latest) (liste des resources, connexion entre Terraform et AWS, etc.)

Ces sites seront souvent cités au cours du lab, mais vous pouvez déjà les ajouter à vos favoris.

## Première étape
Une fois le votre environnement initialisé, vous pouvez démarrer avec la première étape [ici](/docs/step01-simpleExample.md).
