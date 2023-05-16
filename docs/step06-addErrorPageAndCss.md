# Etape 6: Ajout d'une page d'erreur et d'une feuille de style

Dans l'étape précédente, à la déclaration de la ressource de type `aws_s3_bucket_website_configuration` dans le fichier `static_website/main.tf`, on a définit un `index_document`, qui existant déjà, et un `error_document`, qui n'existe pas encore.  
Dans cette dernière étape, on va ajouter cette page d'erreur et en abordant des fonctionnalités avancées de Terraform.

## Ajout de la page d'erreur comme ressource à part
Avec notre configuration actuelle si on accède à une URL invalide de notre site (par exemple en rajoutant `/oups` à l'URL de base), on tombe sur une page indiquant que le fichier `error.html` est introuvable:
![error.html not found](/docs/assets/step06-notFound.png)

Pour commencer, dupliquez le fichier `index.html` dans le répertoire `src` en utilisant `error.html` comme nom. Changez quelques éléments dans le `body` du nouveau fichier pour le transformer en page d'erreur.  

Ensuite, dans le fichier `infra/main.tf`, dupliquez la ressource `aws_s3_object.index` afin de créer une ressource `aws_s3_object.error` pour ajouter le fichier `error.html` comme nouvel objet dans le bucket:
<details>
<summary>Ajout dans le fichier <code>infra/main.tf</code></summary>

```hcl
resource "aws_s3_object" "error" {
  bucket       = module.s3_bucket.bucket_id
  key          = "error.html"
  source       = "../src/error.html"
  content_type = "text/html"
}
```
</details>

Lancez un `terraform apply`, et tentez à nouveau d'accéder à une URL invalide de votre site, vous devriez obtenir la page d'erreur:
![Page d'erreur](/docs/assets/step06-errorPage.png)

## Optimisation du code avec un `for_each`
Après l'ajout de la page d'erreur, nous avons les lignes suivantes dans le fichier `infra/main.tf` pour déclarer les objets du bucket:
```hcl
resource "aws_s3_object" "index" {
  bucket       = module.s3_bucket.bucket_id
  key          = "index.html"
  source       = "../src/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = module.s3_bucket.bucket_id
  key          = "error.html"
  source       = "../src/error.html"
  content_type = "text/html"
}
```
Ces 2 blocs de code se ressemblent, avec un langage de programmation classique on chercherait à factoriser cette partie, on peut aussi le faire avec Terraform.  
Pour cela on va combiner les éléments suivants:
- L'argument [`for_each`](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each) dans un bloc `resource` permet de faire créer plusieurs ressources avec un seul bloc
- La function [`toset`](https://developer.hashicorp.com/terraform/language/functions/toset) qui permet de transformer une [`list`](https://developer.hashicorp.com/terraform/language/expressions/types#lists-tuples) de strings en `set`
- L'objet `each` et sa propriété `key` qui ne sont disponibles que dans le cas d'un `for_each`, et qui permettent d'accéder à la valeur de l'instance en cours

L'idée est de remplacer les 2 ressources `aws_s3_object` en un seul bloc `resource` avec un `for_each` auquel on passe nos 2 noms de fichiers.  
Essayer de faire la modification vous-même avant de regarder la solution ci-dessous:
<details>
<summary>Remplacer les 2 ressources par le bloc suivant:</summary>

```hcl
resource "aws_s3_object" "files" {
  for_each = toset(["index.html", "error.html"])

  bucket       = module.s3_bucket.bucket_id
  key          = each.key
  source       = "../src/${each.key}"
  content_type = "text/html"
}
```
</details>

Lancez un `terraform apply`, vous constatez que Terraform supprime les objets pour les recréez, c'est normal car on a changé leur noms logiques, comme lorsque l'on a ajouté un premier module à l'étape 2 de ce lab.

## Ajout de la feuille de style
Si vous êtes développeur web, cela ne doit pas vous plaire de voir le `css` qui est placé dans une balise `style` et dupliqué dans les 2 fichiers `html`.  
Au début du lab c'était nécessaire de procéder comme cela, mais depuis qu'a activé la fonctionnalité de static website, on peut déplacer le `css` dans un fichier à part.  

Corrigez cela en déplaçant le `css` dans un nouveau fichier `src/main.css`:
<details>
<summary>Contenu du fichier <code>src/main.css</code>:</summary>

```css
body {
    font-family: 'Trebuchet MS', 'Lucida Sans Unicode', 'Lucida Grande', 'Lucida Sans', Arial, sans-serif;
    background-color: white;
}

main {
    background-color: whitesmoke;
    border: 2px groove #7646a7;
    border-radius: 10px;
    width: 600px;
    margin: 20px 0 0 20px;
    padding: 10px;
}

header {
    text-align: center;
}
```
</details>

Puis dans chaque fichier `html`, remplacez la balise `head/style` par un lien vers le fichier `main.css`.  
<details>
<summary>Balise <code>head/link</code> pour chaque fichier <code>html</code>:</summary>

```html
<head>
    <!-- ... -->
    <link rel="stylesheet" href="main.css">
</head>
```
</details>

De retour dans le code Terraform, il faut modifier le fichier `infra/main.tf` pour que la feuille de style soit envoyée en tant qu'objet dans le bucket.  
<details>
<summary>On pourrait faire cela en l'ajoutant dans la liste du <code>for_each</code> comme ceci:</summary>

```hcl
resource "aws_s3_object" "files" {
  for_each = toset(["index.html", "error.html", "main.css"])

  bucket       = module.s3_bucket.bucket_id
  key          = each.key
  source       = "../src/${each.key}"
  content_type = "text/html"
}
```
</details>

Mais on va avoir un problème avec l'argument `content_type`, qui doit être `text/html` pour les fichiers `html`, et `text/css` pour le fichier `css`.  
On devrait s'en sortir en utilisant l'extension de chaque fichier au lieu de mettre `text/html` en dur. Il y a une fonction Terraform qui va nous aider pour cela. Essayer de trouver quelle est cette fonction en fouillant dans [cette section](https://developer.hashicorp.com/terraform/language/functions) de la documentation.  
Si vous n'avez pas trouvé, ce n'est pas grave, il s'agit de cette [function](https://developer.hashicorp.com/terraform/language/functions/split). Essayer de modifier le code pour utiliser cette fonction et résoudre notre "problème".  
<details>
<summary>Si vous n'avez pas trouvé, ce n'est pas grave non plus, dépliez la solution ci-dessous:</summary>

```hcl
resource "aws_s3_object" "files" {
  for_each = toset(["index.html", "error.html", "main.css"])

  bucket       = module.s3_bucket.bucket_id
  key          = each.key
  source       = "../src/${each.key}"
  content_type = "text/${split(".", each.key)[1]}"
}
```
</details>

## Application des changements
Vous pouvez relancer un `terraform apply` qui devrait ajouter un seul fichier (le `main.css`) et... c'est tout. Pourtant nous avons modifié le contenu des 2 fichiers `html` donc Terraform devrait le détecter et mettre à jour ces fichiers ? 🤔  
Et bien non, comme le contenu des fichiers n'est pas dans son _state_, Terraform ne détecte pas la différence et ne propose donc pas d'écraser ces 2 fichiers.  
Dans ce cas, on utilise l'option `-replace` des commandes `plan` et `apply`. Celle-ci permet de forcer la recréation d'une ressource. Exemple dans notre cas (avec en plus l'option `-auto-approve` pour approuver directement les changements):
```shell
terraform apply -auto-approve -replace='aws_s3_object.files["index.html"]' -replace='aws_s3_object.files["error.html"]'
```
Cette fois les fichiers vont être écrasés sur le bucket et la nouvelle version sera en place.

## Conclusion
Félicitations vous avez atteint l'ultime étape de ce lab 🚀🥳  
Mais ce lab n'est qu'un point de départ et il y a encore plein de choses à apprendre dans le monde de Terraform. N'hésitez pas à continuer d'explorer par vous-même, il existe également d'autres [tutoriels](https://developer.hashicorp.com/terraform/tutorials) sur le site officiel.  
N'hésitez pas à vous référer au paragraphe [suivant](/README.md#a-propos-de-la-documentation-de-terraform) au début de ce lab pour voir les liens vers les sections principales de la documentation officielle.  

Dernier point avant de partir, quand vous aurez terminé n'oubliez pas de supprimer vos ressources dans AWS avec la commande suivante:
```shell
terraform destroy -auto-approve
```
(A utiliser sur vos ressources de test mais pas en production bien entendu).
