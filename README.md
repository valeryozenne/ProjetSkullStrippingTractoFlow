# README

## Description du projet

Segmenter de manière automatique le cerveau

## Methodes

6 apprentissages différents ont été testé avec un reseau Unet 

### Pré-traitement

* dwidenoise (de MRtrix) (obligatoire ou alternative similaire)
 Denoising is essential for robust segmentation. 

* un double filtre N4 (de ants) (optionnel)

The protocol IRM utilisé ici diffère largement des protocols de diffusion sur volontaires qui sont extrement standardisés.
En particulier les antennes têtes vont générés un biais d'intensité et niveau de bruit relativement proche quelque soit le scanner utilisé.
Ici, les conditions sont très différentes, le parc de scanner, ou d'antennes est moins homogène, on aura parfois recours à une antenne de surface parfois à une antenne volumique, la position de l'antenne par rapport à l'échantillon est relative à l'utilisateur et enfin la découpe est aussi utilisateur dépendant.
En conséquence, les biais d'intensité risque de varier fortement d'une acquisition à l'autre. Pour pallier à ce problème, l'utilisation d'un filtre N4 est recommandé.
J'utilise ici deux fois le filtre N4, (c'est une habitude sur les donnes ex-vivo).

* downsampling (optionnel)

C'est uniquement pour gagner du temps

* segmentation

[TODO] il faudra affiner les segmentations et reboucher certains trous.


### Apprentissage

le script d'apprentissage a été gracieusement fourni par Nick Tustison.

en entrée N=8 de S#1 à S#8 échantillons

* soit les b0 individuels ( N=5*8=40)
* soit les b0 moyenné (N=1*8=8)
* soit les dw moyenné (N=1*8=8)

soit 3 apprentissages *2 pour avec Gado et sans Gado.

[IMPORTANT] le nombre de donnée est vraiment très sous-optimal. 
Il sera nécessaire d'intégrer des données d'un autre site, scanner pour espèrer un minimum de robustesse. 

### pour le test, 

en test N=1 avec S#9 a été utilisé.

## Résultats


## Apprentissage 


 ##  Prédiction



## Listes des tâches

- [en cours] j'avais oublié de bien mettre les strides
- [en cours] utiliser le double N4 de bigcalculo par ex 
- [TODO] relancer le modèle

- [OK] rapatrier l'apprentissage
- [TODO]rapatrier la prédiction
- [TODO] ajouter le dockerfile
- [TODO] creer un entrypoint
- [TODO] trouver un endroit au stocker les données en ligne 

## Partie 1 : Préparation des données

## Partie 2 : Training

## Partie 3 : prédiction

## Partie 4 : Deploiement






