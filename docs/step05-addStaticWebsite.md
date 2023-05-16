# Etape 5: Ajouter la fonctionnalité de static website

Dans cette étape on va utiliser la fonctionnalité de [static website](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html) d'Amazon S3 pour héberger notre page web et la rendre publique.  
Initialement cela devait être l'objectif de ce lab, mais comme cela demande des ressources supplémentaires, notamment pour l'accès public, on s'en occupe maintenant.

## Création d'un nouveau module
L'ajout du static website va se faire dans un nouveau module qu'on va placer dans le dossier `infra/static_website`. Ce nouveau module va prendre en paramètre entrant l'identifiant du bucket, donc on va initialiser le fichier `static_website/variables.tf` avec une variable `bucket_id` de type `string`.  
<details>
<summary>Contenu du fichier <code>static_website/variables.tf</code></summary>

```hcl
variable "bucket_id" {
  type        = string
  description = "The id of the bucket to activate static website feature in"
}
```
</details>

On peut également ajouter dès maintenant l'appel au module depuis le module _root_:
<details>
<summary>Appel du module depuis le fichier <code>infra/main.tf</code></summary>

```hcl
module "static_website" {
  source = "./static_website"

  bucket_id = module.s3_bucket.bucket_id
}
```
</details>

## Ajout de la ressource principale
La ressource à utiliser pour activer le static website est [`aws_s3_bucket_website_configuration`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration). On peut reprendre l'exemple du registry en supprimant la partie `routing_rule` donc on n'a pas besoin, et en utilisant la variable `bucket_id` de notre module pour référencer le bucket.  
On place le tout dans le fichier `main.tf` du module:
<details>
<summary>Contenu du fichier <code>static_website/main.tf</code></summary>

```hcl
resource "aws_s3_bucket_website_configuration" "web" {
  bucket = var.bucket_id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
```
</details>

## Activation de l'accès public sur le bucket S3
Si on appliquait nos modifications dès maintenant, la fonctionnalité de static website serait bien appliquée dans les propriétés du bucket:
![propriétés du bucket](/docs/assets/step05-staticwebsite.png)  
Mais l'accès au site serait bloqué car par défaut AWS bloque le trafic public sur les buckets et les objets S3:
![erreur 403](/docs/assets/step05-403error.png)   

### Modification pour le bucket
Pour modifier ce comportement par défaut on va dans un premier temps activer l'accès public sur le bucket, en utilisant la ressource [`aws_s3_bucket_public_access_block`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block). Dans le fichier `main.tf`, on ajoute cette ressource, on utilise la variable `bucket_id` comme bucket et on passe les flags `ignore_public_acl` et `restrict_public_access` à `false`:
<details>
<summary>Ajout dans le fichier <code>static_website/main.tf</code></summary>

```hcl
resource "aws_s3_bucket_public_access_block" "public_get" {
  bucket = var.bucket_id

  ignore_public_acls      = false
  restrict_public_buckets = false
}
```
</details>

Cela permet de passer à _Off_ le blocage suivant dans la console AWS:
![block public access](/docs/assets/step05-blockPublicAccess.png)

### Modification pour les objets dans le bucket
Les choses sont un peu plus compliquées pour débloquer l'accès public pour les objets contenus dans le bucket. L'objectif est de créer une [_policy_ ](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteAccessPermissionsReqd.html#bucket-policy-static-site) pour autoriser l'accès public à tous les objets du bucket.  
Cela ressemblera à cela dans la console:
![Bucket policy](/docs/assets/step05-bucketPolicy.png)  
Pour faire cela avec Terraform, on va utiliser la ressource [`aws_s3_bucket_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy). Dans l'exemple du registry, on voit pour la première fois la notation suivante:
```hcl
data "aws_iam_policy_document" "allow_access_from_another_account" {
    # ...
}
```
Il s'agit d'une [_data source_](https://developer.hashicorp.com/terraform/language/data-sources), un concept de Terraform qui permet de référencer une ressource existante, qui peut être créée en dehors de Terraform ou dans un autre module.  
Les _data sources_ sont souvent utilisées pour récupérer des informations d'une ressource à partir de son id. Ici on va utiliser une _data source_ sur le bucket pour récupérer son ARN (pour [Amazon Resource Name](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference-arns.html)).  
Et on va utiliser une autre data source pour construire la policy comme dans l'exemple du registry, ce qui donne les ajouts suivants:
<details>
<summary>Ajout dans le fichier <code>static_website/main.tf</code></summary>

```hcl
data "aws_s3_bucket" "web" {
  bucket = var.bucket_id
}

data "aws_iam_policy_document" "public_get" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${data.aws_s3_bucket.web.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "public_get" {
  depends_on = [aws_s3_bucket_public_access_block.public_get]

  bucket = var.bucket_id
  policy = data.aws_iam_policy_document.public_get.json
}
```
</details>

## Ajout de l'URL du site en output
Avant d'appliquer nos changements, on va faire en sorte que l'URL du site statique soit exposée en tant qu'output, donc on l'ajoute dans un premier temps en tant qu'output du module `static_website`:
<details>
<summary>Contenu du fichier <code>static_website/outputs.tf</code></summary>

```hcl
output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.web.website_endpoint}"
}
```
</details>

Puis en tant qu'output du module _root_:
<details>
<summary>Contenu du fichier <code>infra/outputs.tf</code></summary>

```hcl
output "website_url" {
  value = module.static_website.website_url
}
```
</details>

## Application et vérification du résultat:
Vous pouvez maintenant lancer un `terraform apply` pour appliquer tous ces changements. Dans le résultat de la commande se trouve une URL sous la forme `http://NOM-DU-BUCKET.s3-website.ca-central-1.amazonaws.com` qui permet d'accéder au site:
![Le site dans le navigateur](/docs/assets/step05-browser.png)

## Etape suivante
Pour terminer ce lab on va ajouter une page d'erreur et une feuille de style en abordant des fonctionnalités plus avancées de Terraform, c'est par [ici](/docs/step06-addErrorPageAndCss.md).