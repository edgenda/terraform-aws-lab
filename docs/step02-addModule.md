# Etape 2: Ajout d'un module

Dans cette étape nous allons introduire la notion de _module_ qui permet de mieux organiser notre code Terraform.  

> Si vous avez rencontré des soucis sur la première étape, vous pouvez utiliser la commande `git checkout -f step01-simpleExample` pour vous placer directement sur la "solution". Sinon vous pouvez poursuivre avec vos propres changements.

## Les modules de Terraform

Comme dans de nombreux langages les modules de Terraform permettent d'organiser le code pour combiner des ressources, et créer des briques facilement réutilisables.  
Jusqu'à présent on a déjà utilisé un module sans le savoir, le module _root_ constitué des fichiers `tf` dans le répertoire de départ (`infra`). Par défaut Terraform utilise tous les fichiers `.tf`dans le répertoire à partir duquel il est lancé, par convention on utilise au moins les 3 fichiers suivants dans chaque module:
- Le fichier `variables.tf` contient les _variables_, les paramètres d'entrée du module
- Le fichier `outputs.tf` contient les _outputs_, les valeurs de sortie du module
- Le fichier `main.tf` qui contient les ressources à créer, ou au moins les principales. On peut créer d'autres fichiers `.tf` pour découper celui-ci et faciliter la lecture du code (ça ne change rien pour Terraform qui met tous les fichiers `.tf` au même niveau quel que soit leur nom)

> La documentation explique avec plus de détails la notion de modules [ici](https://developer.hashicorp.com/terraform/language/modules), ainsi que les conventions sur [cette page](https://developer.hashicorp.com/terraform/language/modules/develop/structure).

## Création d'un premier module

Pour illustrer cela on va déplacer le bucket S3 dans un module.
1. Créez un dossier `s3_bucket` dans le dossier `infra`
2. Dans ce nouveau dossier, créez 3 fichiers `main.tf`, `variables.tf` et `outputs.tf`
3. Notre module va prendre en entrée une variable `bucket_name` avec le nom du bucket, ajoutez ceci dans le fichier `variables.tf`:
```hcl
variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}
```
4. Dans le fichier `s3_bucket/main.tf` on déplace la déclaration du bucket en utilisant la variable comme nom:
```hcl
resource "aws_s3_bucket" "web" {
  bucket = var.bucket_name
}
```
5. Dans le module root, on a besoin de l'id du bucket pour déclarer l'objet qui contient la page `index.html`, donc notre module root doit exposer cet id en tant qu'output, dans le fichier `s3_bucket/outputs.tf`:
```hcl
output "bucket_id" {
  value = aws_s3_bucket.web.id
}
```
6. Notre module `s3_bucket` est prêt mais il faut mettre à jour le module root qui doit l'appeler. Dans le fichier `infra/main.tf`, on remplace la ressource `aws_s3_bucket.web` par l'appel au module:
```hcl
module "s3_bucket" {
  source = "./s3_bucket"

  bucket_name = "s3-aws-tf-lab-${random_pet.pet.id}"
}
```
7. Enfin il faut mettre à jour la ressource `aws_s3_object.index` en utilisant l'output du module comme id de bucket:
```hcl
resource "aws_s3_object" "index" {
  bucket       = module.s3_bucket.bucket_id # <== L'output est appelé ici
  key          = "index.html"
  source       = "../src/index.html"
  content_type = "text/html"
}
```

Les modifications sont terminées, on va pouvoir valider les changements.

## Lancement d'un plan et d'un apply
Depuis le terminal de Cloud9, dans le dossier `infra`, lancez un `terraform plan`.  
Vous obtenez une erreur `Error: Module not installed`, car le module n'est pas installé: après chaque ajout de module, il faut relancer un `terraform init`.  
Une fois que c'est fait, relancez le `terraform plan`. Le plan devrait se dérouler correctement avec le résultat suivant:
```
Plan: 2 to add, 0 to change, 2 to destroy.
```
Terraform prévoit donc d'ajouter 2 ressources et d'en détruire 2, alors qu'on a juste "refactorisé" notre code sans changer aux ressources 🧐  
C'est un effet du state de Terraform: déplacer le bucket dans un module change son nom logique dans la configuration, alors que l'ancien nom est toujours dans le state. Pour Terraform il faut donc supprimer le bucket du module _root_ et créer celui du module `s3_bucket`.  
Et comme l'objet index.html ne peut pas être déplacé d'un bucket à un autre, Terraform pense qu'il faut aussi le supprimer et le recréer.  

Vous pouvez lancer un `terraform apply` et accepter les changements, qui seront appliqués instantanément. Même si c'est sans conséquence ici il faut garder cette mécanique à l'esprit quand on travaille avec Terraform: une des conséquence du state est que le renommage de ressources et le refactoring du code en général peuvent avoir des conséquences. Imaginez avoir fait la même chose sur une base de données de production 🤯  

> Récemment Terraform a ajouté des solutions pour permettre de faciliter le [refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring) du code, notamment avec les blocs `moved`

## Etape suivante
C'est la fin de cette étape, vous pouvez passer à la [suivante](/docs/step03-useTerrascan.md) on l'on va inspecter notre code.
