# Etape 4: Déplacer le backend dans AWS S3

Dans cette étape on va déplacer notre state dans un nouveau bucket S3 et donc remplacer le backend _local_ par le backend [s3](https://developer.hashicorp.com/terraform/language/settings/backends/s3).  

## Création d'un bucket S3 pour stocker notre state

Depuis la [console AWS](https://s3.console.aws.amazon.com/s3/bucket/create?region=ca-central-1), créez un nouveau bucket en choisissant un nom globalement unique. Laissez les autres valeurs par défaut, et cliquez sur le bouton _Create bucket_.  

> A noter qu'on créé ici le bucket à la main, notre code Terraform ne peut pas créer le bucket de son propre state. C'est un problème dit d'oeuf et de poule qui se solutionne en deux temps dans un scénario à l'échelle, soit en créant le bucket par un script, soit avec une autre configuration Terraform chargée de créer les buckets des autres configurations Terraform de l'entreprise (et de positionner les bons droits).

## Migration du state vers le nouveau backend

La déclaration du nouveau backend s'effectue en ajoutant la ligne `backend "s3" {}` comme ceci dans le fichier `versions.tf`:
```hcl
terraform {
  required_providers {
    # ...
  }

  backend "s3" {}
}
```
Il existe différentes façon de [configurer](https://developer.hashicorp.com/terraform/language/settings/backends/configuration) le backend dans la configuration Terraform. Chaque backend a ses spécificités, dans le cas du backend [s3](https://developer.hashicorp.com/terraform/language/settings/backends/s3#configuration) seuls le nom du bucket et la région sont requis.  
Pourtant on n'est pas obligé de les faire apparaître dans le code, pour le vérifier lancez la commande `terraform init` depuis le dossier `infra`. Terraform vous demande 3 choses:
1. Le nom du bucket S3: rentrez le nom que vous avez choisi lors de la création depuis la console AWS
2. Le chemin du fichier dans le bucket: entrez n'importe quel nom de fichier valide (vous pouvez utiliser des `/` pour créer des répertoires)
3. Est-ce que vous voulez copier le state existant vers le nouveau backend: répondez `yes`

Terraform a détecté la présence du state local et propose de migrer automatiquement le state existant. Après cette migration le fichier `infra/terraform.tfstate` est vide, et un nouveau fichier `infra/.terraform/terraform.tfstate` a été créé. Ce dernier contient la configuration du nouveau backend: type de backend, nom de bucket, région, etc.  
Vous pouvez lancer un `terraform plan` ou `terraform apply` pour vérifier la bonne communication avec le nouveau backend: il ne devrait pas y avoir de changement à appliquer.  

A noter qu'au niveau de l'authentification, dans l'environnement Cloud9 il n'y a rien de particulier à faire puisque tout est préconfiguré par le service en utilisant l'identité associée: pas besoin de gérer de credentials dans le cadre de ce lab.

## Etape suivante
Après ce changement de backend on peut passer à l'étape suivante avec l'activation du site [web statique](/docs/step05-addStaticWebsite.md).
