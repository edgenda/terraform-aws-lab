# Etape 3: Analyse du code avec Terrascan

Qui dit Infrastructure as Code dit code, et qui dit code dit qualité de code. Il existe différents outils pour analyser du code Terraform sur différents aspects: respect des bonnes pratiques, détection de problèmes de sécurité et même d'optimisation de coût.  
Dans cette étape on va s'intéresser à [Terrascan](https://github.com/tenable/terrascan) qui tombe principalement dans la seconde catégorie. 

## Installation de Terrascan
Terrascan n'est pas installé par défaut dans Cloud9, il faut le faire via ces quelques lignes dans le terminal:
```bash
curl -L "$(curl -s https://api.github.com/repos/tenable/terrascan/releases/latest | grep -o -E "https://.+?_Linux_x86_64.tar.gz")" > terrascan.tar.gz
tar -xf terrascan.tar.gz terrascan && rm terrascan.tar.gz
sudo install terrascan /usr/local/bin && rm terrascan
```
⚠️ Attention à ne pas utiliser le script fourni sur GitHub car il ne fonctionne pas sur Cloud9.  
La commande `terrascan version` permet de valider l'installation en affichant la version.  

## Analyse du code et remédiation
Depuis le terminal de Cloud9, dans le dossier `infra`, lancez la commande `terrascan scan`. Le problème suivant est remonté:
```shell
Description    :        Enabling S3 versioning will enable easy recovery from both unintended user actions, like deletes and overwrites
File           :        s3_bucket/main.tf
Module Name    :        root
Plan Root      :        s3_bucket
Line           :        1
Severity       :        HIGH
```

Terrascan recommande d'activer la fonctionnalité de [versionning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html) sur le bucket pour permettre la récupération d'objets supprimés par accident.  

En consultant le registry du provider AWS, on trouve la ressource [`aws_s3_bucket_versioning`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) qui sert à activer la fonctionnalité.  

Ajoutez la ressource dans le fichier `s3_bucket/main.tf` et relancez `terrascan scan`. Il ne devrait plus y avoir de problème détecté.

## D'autres outils d'analyse de code
Voici d'autres outils pour analyser notre code:
- La commande `terraform validate` effectue une validation de la syntaxe
- `terraform fmt -recursive` corrige les problèmes d'indentation
- Lancer un `terraform plan` permet aussi de vérifier son code avant de le pousser
- [checkov](https://www.checkov.io/) est un autre outil d'analyse de code statique

> Pour aller encore plus loin, [cette conférence](https://www.youtube.com/watch?v=xhHOW0EF5u8) en anglais explique comment _tester_ du code Terraform et comment le test du code IaC est différent du test du code applicatif.

## Etape suivante
Cette étape marque la fin de la partie "principale" de ce lab, mais si vous le voulez il reste quelques étapes pour aller un peu plus loin, à commencer par [déplacer notre state dans un bucket S3](/docs/step04-useS3Backend.md).  
