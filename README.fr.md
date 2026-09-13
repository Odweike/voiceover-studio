<p align="center"><img src="docs/assets/icon.png" width="96" height="96" alt="Icône de Voiceover Studio"></p>
<h1 align="center">Voiceover Studio</h1>
<p align="center">Enregistrez votre script réplique par réplique. Gardez la prise que vous aimez.</p>
<p align="center"><a href="https://github.com/Odweike/voiceover-studio/releases/download/v0.4.0/Voiceover-Studio-0.4.0-universal.dmg"><strong>Télécharger pour macOS</strong></a> · <a href="https://playrito.site/voiceOver/">Site web</a> · <a href="README.md">English</a> · <a href="README.ru.md">Русский</a> · <a href="README.es.md">Español</a></p>

Une petite application macOS native pour enregistrer des voix off à partir d'un script. Importez votre texte, enregistrez les répliques une par une, comparez les prises et importez les fichiers WAV choisis dans votre logiciel de montage vidéo.

Je l'ai créée pour mon propre flux de travail de voix off et j'ai décidé de la partager. Elle est gratuite, fonctionne hors ligne et ne demande aucun compte.

![Voiceover Studio — aperçu de l'interface en anglais](docs/assets/app-preview-en.png)

*L'interface est disponible en anglais, espagnol, français et russe — à choisir dans les Réglages de l'app.*

## Télécharger et installer

**[Télécharger Voiceover Studio 0.4.0 — DMG universel](https://github.com/Odweike/voiceover-studio/releases/download/v0.4.0/Voiceover-Studio-0.4.0-universal.dmg)**

Nécessite **macOS 14.4 ou ultérieur**. Inclut les binaires Apple Silicon et Intel. L'app a été testée sur Apple Silicon ; cette version n'a pas encore été testée sur un Mac Intel physique. L'interface suit la langue de votre Mac (anglais, espagnol, français ou russe) et peut être modifiée dans les Réglages de l'app.

1. Ouvrez le DMG et faites glisser **Voiceover Studio** dans **Applications**.
2. Éjectez le DMG et ouvrez l'app depuis Applications.
3. Autorisez l'accès au micro lors du premier enregistrement.

**Note de premier lancement :** cette version indépendante utilise une signature ad hoc et n'est **pas notariée par Apple**. macOS peut la bloquer. Si vous faites confiance au téléchargement, après avoir tenté de la lancer, utilisez **Réglages Système → Confidentialité et sécurité → Ouvrir quand même**. Consultez les [instructions officielles d'Apple](https://support.apple.com/102445).

Téléchargez depuis les [Releases](https://github.com/Odweike/voiceover-studio/releases) de ce dépôt. Un [fichier de somme SHA-256](https://github.com/Odweike/voiceover-studio/releases/download/v0.4.0/SHA256SUMS.txt) accompagne le DMG. Inutile d'installer Xcode, Python ou Node.js pour utiliser l'app.

## Ce qu'elle fait

- **Le script à côté de l'enregistreur.** Texte russe et anglais dans un tableau redimensionnable ; utilisez une langue ou les deux.
- **Un enregistrement par réplique.** Enregistrez un bloc entier ou divisez-le avec des marqueurs `[voice:...]`.
- **Plusieurs prises.** Écoutez, mettez en pause, choisissez la meilleure prise et déplacez les autres dans la Corbeille.
- **Audio prêt pour le montage.** Fichiers WAV mono, 48 kHz, PCM 24 bits.
- **Des projets séparés.** Chaque import crée un nouveau dossier : les enregistrements de scripts différents ne se mélangent pas.
- **Stockage local et récupération.** JSON et WAV simples, écriture atomique des métadonnées et journal d'enregistrement en cours.

C'est un enregistreur ciblé, pas un éditeur audio complet. Il ne recoupe ni ne traite le son, n'écrit pas dans Excel et ne se synchronise pas automatiquement avec Premiere. Importez les fichiers WAV dans votre éditeur habituel pour ce travail.

## Votre première voix off

L'app ouvre un petit exemple au premier lancement.

1. Choisissez **Importer un script** pour importer un fichier JSON/XLSX. Pour continuer un projet existant, choisissez **Ouvrir un projet** et sélectionnez son dossier.
2. Cliquez sur **Enregistrer cette réplique** à côté d'une ligne, puis sur **Enregistrer**. Utilisez **Nouvelle prise** pour réessayer.
3. Écoutez et sélectionnez la prise à conserver. La première prise est sélectionnée automatiquement.
4. Cliquez sur **Afficher le projet** pour ouvrir le dossier contenant vos fichiers WAV et `manifest.json`.

L'import crée toujours un **nouveau** projet. Pour continuer à travailler sur le même script et ses enregistrements, rouvrez son dossier de projet au lieu de l'importer à nouveau.

## Apporter un script

Commencez avec [le JSON d'exemple](Resources/scenario.json). Chaque bloc nécessite un ID, un numéro d'affichage et les deux champs de langue ; l'un d'eux peut être vide :

```json
[
  {
    "id": "intro",
    "number": "1",
    "russian": "Привет! Сегодня покажу, как это работает.",
    "english": "Hello! Today I'll show you how this works."
  }
]
```

Pour XLSX, utilisez un classeur simple d'une seule feuille : **la ligne 1 contient les en-têtes, la colonne D le texte russe et la colonne E le texte anglais**. Les numéros d'affichage vont dans la colonne A. Les formules ne sont pas calculées.

Besoin de plusieurs enregistrements dans un même bloc ? Placez un marqueur avant chaque réplique :

```text
[voice:intro-greeting]
Hello!

[voice:intro-start]
Let's get started.
```

Les marqueurs doivent être uniques dans tout le script. Si les deux langues sont présentes, utilisez les mêmes marqueurs dans le même ordre. Consultez le [format de script complet](docs/SCRIPT_FORMAT.md) pour les colonnes optionnelles et les limites d'import.

## Vos fichiers restent à vous

Les projets sont stockés dans `~/Movies/Voiceover Studio/Projects/` par défaut. Chaque dossier contient le script, un manifeste et un répertoire `Recordings`. Sauvegardez **le dossier entier** pour préserver la relation entre répliques, prises et sélections.

L'app n'a ni services réseau, ni analytique, ni compte, ni envoi vers le cloud. Un journal temporaire aide à récupérer un enregistrement dont les métadonnées n'ont pas été sauvegardées avant une interruption. Après un plantage ou une panne, vérifiez l'audio récupéré : conserver le fichier ne garantit pas qu'un WAV interrompu soit valide.

Les projets de la version personnelle d'origine peuvent être ouverts sur place. Fermez d'abord l'ancienne app. Voir les [détails de stockage et de récupération](docs/ARCHITECTURE.md).

## Compiler depuis les sources

Utilisez macOS 14.4+ et une toolchain Swift 6+ (Xcode Command Line Tools pour une compilation native ; Xcode complet pour le paquet universel).

```sh
git clone https://github.com/Odweike/voiceover-studio.git
cd voiceover-studio
./build.sh
open "build/Voiceover Studio.app"
```

Lancez le bundle `.app` plutôt que `swift run`, afin que macOS lise la description de l'autorisation du micro et l'exemple intégré.

```sh
swift test                     # tests de non-régression
python3 tools/check.py         # valide le bundle compilé
./tools/package-dmg.sh         # app universelle, DMG et somme de contrôle
```

L'app utilise SwiftUI, AVFoundation et Foundation. **Aucune dépendance tierce à l'exécution.** [Vue d'ensemble de l'architecture](docs/ARCHITECTURE.md) · [Guide de contribution](CONTRIBUTING.md) · [Guide de release](RELEASING.md)

## Retours et contributions

Un bug ou une idée d'amélioration ? [Ouvrez une issue](https://github.com/Odweike/voiceover-studio/issues). Indiquez votre version de macOS, le comportement attendu et les étapes pour le reproduire. Un script d'exemple anonymisé aide ; merci de ne pas joindre d'enregistrements privés.

Les pull requests petites et ciblées sont les bienvenues. L'identité des enregistrements, la sécurité des fichiers et un flux de travail simple comptent plus que l'ajout de couches ou de fonctionnalités.

## Licence

[MIT](LICENSE). Réalisée par [Maxim Marin](https://github.com/Odweike).
