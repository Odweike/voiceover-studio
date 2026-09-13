'use client';

import Image from 'next/image';
import { useState } from 'react';
import { ArrowDown, ArrowUpRight, Check, Mic, FolderOpen } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';

const repo = 'https://github.com/Odweike/voiceover-studio';
const dmg = 'https://playrito.site/voiceOver/downloads/Voiceover-Studio-0.4.0-universal.dmg';
const words = {
  ru: {
    skip: 'К содержимому', install: 'Установка', headline: <>Озвучка.<br/>Реплика за репликой.</>,
    intro: 'Откройте сценарий, запишите каждую реплику и выберите лучший дубль. Готовые WAV-файлы — для вашего монтажа.',
    download: 'Скачать для macOS', free: 'Бесплатно · без регистрации · открытый код',
    compatibility: 'macOS 14.4+ · Apple Silicon и Intel', version: 'Версия 0.4.0 · универсальный DMG',
    caption: 'Настоящее окно приложения. Демонстрационный сценарий.',
    note: 'Независимая версия без нотарификации Apple. При первом запуске macOS может попросить разрешение.',
    installLink: 'Как открыть приложение', workflow: 'От сценария к готовым дублям.',
    steps: [ ['Импортируйте сценарий', 'Откройте JSON или XLSX с русским и английским текстом. Можно использовать только один язык.'], ['Запишите реплики', 'Несколько дублей, прослушивание и выбор лучшего — рядом с текстом. Не нужно искать запись на длинном таймлайне.'], ['Заберите WAV', 'Откройте папку проекта и перенесите аудиофайлы в Premiere, Resolve или другой редактор.'] ],
    spec: 'WAV · 48 кГц · 24 бит · моно', privacy: 'Ваш голос остаётся на вашем Mac.',
    privacyText: 'Приложение работает офлайн. Сценарии, записи и выбранные дубли лежат в обычной папке проекта. Без аккаунта и облачной загрузки.',
    installTitle: 'Установить за минуту.',
    installSteps: ['Скачайте и откройте DMG.', 'Перетащите Voiceover Studio в Applications («Программы»).', 'Откройте приложение из «Программ». Разрешите микрофон при первой записи.'],
    blocked: 'macOS не открывает приложение?',
    blockedText: 'У этого выпуска нет нотарификации Apple. Если вы доверяете загрузке, после попытки запуска откройте «Системные настройки → Конфиденциальность и безопасность» и нажмите «Всё равно открыть».',
    apple: 'Инструкция Apple', questions: 'Пара деталей перед записью',
    faqs: [ ['Это бесплатно?', 'Да. Приложение и исходники доступны бесплатно по лицензии MIT. Подписки, аккаунта и ограничений по количеству дублей нет.'], ['Подойдёт любая таблица Excel?', 'Нужен простой однолистовый XLSX: заголовки в первой строке, русский текст в D, английский — в E. Формулы не вычисляются. Полный формат и готовый JSON-пример есть в README.'], ['Это полноценный аудиоредактор?', 'Нет. Voiceover Studio помогает записывать озвучку и выбирать дубли. Обрезка, обработка звука и монтаж выполняются в вашем редакторе.'], ['Где хранятся записи?', 'По умолчанию — в Movies / Voiceover Studio / Projects. Кнопка «Показать проект» открывает нужную папку. Для резервной копии сохраните её целиком.'] ],
    readme: 'Документация', issues: 'Сообщить об ошибке',
    intel: 'Проверено на Apple Silicon. Intel-сборка включена; на физическом Intel Mac этот выпуск пока не тестировался.',
  },
  en: {
    skip: 'Skip to content', install: 'Install', headline: <>Voiceovers.<br/>One line at a time.</>,
    intro: 'Open your script, record each line and choose your best take. Get individual WAV files, ready for your edit.',
    download: 'Download for macOS', free: 'Free · no account · open source',
    compatibility: 'macOS 14.4+ · Apple Silicon & Intel', version: 'Version 0.4.0 · universal DMG',
    caption: 'The actual app, showing a demonstration script.',
    note: 'Independent release, not notarized by Apple. macOS may require approval on first launch.',
    installLink: 'How to open the app', workflow: 'From script to selected takes.',
    steps: [ ['Bring your script', 'Import JSON or a simple XLSX with Russian and English text. A single language works too.'], ['Record each line', 'Record takes, listen and pick your favorite right beside the text. No searching through one long timeline.'], ['Take your WAVs', 'Open the project folder and bring the audio into Premiere, Resolve or your preferred editor.'] ],
    spec: 'WAV · 48 kHz · 24-bit · mono', privacy: 'Your voice stays on your Mac.',
    privacyText: 'The app works offline. Scripts, recordings and take selections live in an ordinary project folder. No account or cloud upload.',
    installTitle: 'A minute to install.',
    installSteps: ['Download and open the DMG.', 'Drag Voiceover Studio into Applications.', 'Open it from Applications. Allow microphone access when you first record.'],
    blocked: 'macOS blocked the first launch?',
    blockedText: 'This release is not notarized by Apple. If you trust the download, after trying to launch it, open System Settings → Privacy & Security and choose Open Anyway.',
    apple: 'Apple’s instructions', questions: 'A few things to know',
    faqs: [ ['Is it free?', 'Yes. The app and source code are free under the MIT license. No subscription, account or take limits.'], ['Can I use any Excel workbook?', 'Use a simple single-sheet XLSX: headers in row 1, Russian text in D, English in E. Formulas are not calculated. The README has the full format and a ready-to-use JSON sample.'], ['Is this an audio editor?', 'No. Voiceover Studio helps you record voiceovers and select takes. Trim, process and edit the audio in your preferred editor.'], ['Where are my recordings?', 'By default, under Movies / Voiceover Studio / Projects. The “Show Project” button opens the folder. Back up the entire folder to preserve your work.'] ],
    readme: 'Documentation', issues: 'Report a bug',
    intel: 'Tested on Apple Silicon. An Intel build is included; this release has not yet been tested on a physical Intel Mac.',
  },
  es: {
    skip: 'Ir al contenido', install: 'Instalación', headline: <>Locución.<br/>Línea por línea.</>,
    intro: 'Abre tu guion, graba cada línea y elige la mejor toma. Obtén archivos WAV listos para tu edición.',
    download: 'Descargar para macOS', free: 'Gratis · sin registro · código abierto',
    compatibility: 'macOS 14.4+ · Apple Silicon e Intel', version: 'Versión 0.4.0 · DMG universal',
    caption: 'La app real, mostrando un guion de demostración.',
    note: 'Versión independiente, no notarizada por Apple. macOS puede pedir aprobación en el primer inicio.',
    installLink: 'Cómo abrir la app', workflow: 'Del guion a las tomas elegidas.',
    steps: [ ['Importa tu guion', 'Abre un JSON o un XLSX sencillo con texto en ruso e inglés. También funciona con un solo idioma.'], ['Graba cada línea', 'Graba tomas, escúchalas y elige tu favorita junto al texto. Sin buscar en una larga línea de tiempo.'], ['Llévate los WAV', 'Abre la carpeta del proyecto y lleva el audio a Premiere, Resolve o tu editor preferido.'] ],
    spec: 'WAV · 48 kHz · 24 bits · mono', privacy: 'Tu voz se queda en tu Mac.',
    privacyText: 'La app funciona sin conexión. Los guiones, las grabaciones y las selecciones de tomas viven en una carpeta de proyecto normal. Sin cuenta ni subida a la nube.',
    installTitle: 'Un minuto para instalar.',
    installSteps: ['Descarga y abre el DMG.', 'Arrastra Voiceover Studio a Aplicaciones.', 'Ábrela desde Aplicaciones. Permite el acceso al micrófono la primera vez que grabes.'],
    blocked: '¿macOS bloqueó el primer inicio?',
    blockedText: 'Esta versión no está notarizada por Apple. Si confías en la descarga, tras intentar abrirla, ve a Ajustes del Sistema → Privacidad y seguridad y elige Abrir de todos modos.',
    apple: 'Instrucciones de Apple', questions: 'Algunas cosas que debes saber',
    faqs: [ ['¿Es gratis?', 'Sí. La app y el código fuente son gratuitos bajo la licencia MIT. Sin suscripción, cuenta ni límites de tomas.'], ['¿Sirve cualquier libro de Excel?', 'Usa un XLSX sencillo de una sola hoja: encabezados en la fila 1, texto ruso en D, inglés en E. Las fórmulas no se calculan. El README tiene el formato completo y un JSON de ejemplo listo para usar.'], ['¿Es un editor de audio?', 'No. Voiceover Studio te ayuda a grabar locuciones y elegir tomas. Recorta, procesa y edita el audio en tu editor preferido.'], ['¿Dónde están mis grabaciones?', 'Por defecto, en Movies / Voiceover Studio / Projects. El botón «Mostrar proyecto» abre la carpeta. Haz copia de toda la carpeta para conservar tu trabajo.'] ],
    readme: 'Documentación', issues: 'Informar de un error',
    intel: 'Probada en Apple Silicon. Se incluye una compilación Intel; esta versión aún no se ha probado en un Mac Intel físico.',
  },
  fr: {
    skip: 'Aller au contenu', install: 'Installation', headline: <>Voix off.<br/>Réplique par réplique.</>,
    intro: 'Ouvrez votre script, enregistrez chaque réplique et choisissez la meilleure prise. Obtenez des fichiers WAV prêts pour le montage.',
    download: 'Télécharger pour macOS', free: 'Gratuit · sans compte · open source',
    compatibility: 'macOS 14.4+ · Apple Silicon et Intel', version: 'Version 0.4.0 · DMG universel',
    caption: 'La vraie app, avec un script de démonstration.',
    note: 'Version indépendante, non notariée par Apple. macOS peut demander une approbation au premier lancement.',
    installLink: 'Comment ouvrir l’app', workflow: 'Du script aux prises choisies.',
    steps: [ ['Apportez votre script', 'Importez un JSON ou un XLSX simple avec du texte russe et anglais. Une seule langue fonctionne aussi.'], ['Enregistrez chaque réplique', 'Enregistrez des prises, écoutez-les et choisissez votre préférée juste à côté du texte. Sans chercher dans une longue timeline.'], ['Récupérez vos WAV', 'Ouvrez le dossier du projet et importez l’audio dans Premiere, Resolve ou votre éditeur préféré.'] ],
    spec: 'WAV · 48 kHz · 24 bits · mono', privacy: 'Votre voix reste sur votre Mac.',
    privacyText: 'L’app fonctionne hors ligne. Scripts, enregistrements et sélections de prises vivent dans un dossier de projet ordinaire. Aucun compte ni envoi vers le cloud.',
    installTitle: 'Une minute pour installer.',
    installSteps: ['Téléchargez et ouvrez le DMG.', 'Faites glisser Voiceover Studio dans Applications.', 'Ouvrez-la depuis Applications. Autorisez le micro lors du premier enregistrement.'],
    blocked: 'macOS a bloqué le premier lancement ?',
    blockedText: 'Cette version n’est pas notariée par Apple. Si vous faites confiance au téléchargement, après avoir tenté de la lancer, ouvrez Réglages Système → Confidentialité et sécurité et choisissez Ouvrir quand même.',
    apple: 'Instructions d’Apple', questions: 'Quelques points à connaître',
    faqs: [ ['Est-ce gratuit ?', 'Oui. L’app et son code source sont gratuits sous licence MIT. Ni abonnement, ni compte, ni limite de prises.'], ['Puis-je utiliser n’importe quel classeur Excel ?', 'Utilisez un XLSX simple d’une seule feuille : en-têtes en ligne 1, texte russe en D, anglais en E. Les formules ne sont pas calculées. Le README contient le format complet et un JSON d’exemple prêt à l’emploi.'], ['Est-ce un éditeur audio ?', 'Non. Voiceover Studio vous aide à enregistrer des voix off et à choisir les prises. Recoupez, traitez et montez l’audio dans votre éditeur préféré.'], ['Où sont mes enregistrements ?', 'Par défaut, dans Movies / Voiceover Studio / Projects. Le bouton « Afficher le projet » ouvre le dossier. Sauvegardez le dossier entier pour préserver votre travail.'] ],
    readme: 'Documentation', issues: 'Signaler un bug',
    intel: 'Testée sur Apple Silicon. Une compilation Intel est incluse ; cette version n’a pas encore été testée sur un Mac Intel physique.',
  },
};

export default function Home() {
  const [language, setLanguage] = useState<'ru' | 'en' | 'es' | 'fr'>('ru');
  const t = words[language];
  return <div lang={language}>
    <a className="skip" href="#main">{t.skip}</a>
    <header className="site-header shell">
      <a href="#main" className="brand" aria-label="Voiceover Studio"><Image unoptimized src="./icon.png" width="40" height="40" alt=""/>Voiceover Studio</a>
      <nav aria-label={{ru:'Навигация',en:'Navigation',es:'Navegación',fr:'Navigation'}[language]}>
        <a href="#install" className="nav-install">{t.install}</a>
        <a href={repo} aria-label="GitHub"><ArrowUpRight size={20}/><span>GitHub</span></a>
        <div className="language" aria-label="Language">
          {(['ru','en','es','fr'] as const).map(lang => <Button key={lang} variant="ghost" size="sm" aria-pressed={language === lang} onClick={() => { setLanguage(lang); document.documentElement.lang = lang; }}>{lang.toUpperCase()}</Button>)}
        </div>
      </nav>
    </header>
    <main id="main">
      <section className="hero shell">
        <div className="hero-copy">
          <h1>{t.headline}</h1>
          <p className="intro">{t.intro}</p>
          <a className="download" href={dmg}><ArrowDown size={22}/>{t.download}</a>
          <p className="compatibility">{t.compatibility}<br/><span>{t.version}</span></p>
          <p className="free"><Check size={16}/>{t.free}</p>
        </div>
        <figure className="app-preview">
          <div className="preview-top"><span className="record-dot"/>Voiceover Studio<span className="preview-spec">WAV / 48 kHz</span></div>
          <div className="screenshot-window"><Image unoptimized src="./app-screenshot.png" alt={t.caption} width="1120" height="760" priority/></div>
          <figcaption>{t.caption}</figcaption>
        </figure>
      </section>
      <div className="release-note shell"><p>{t.note} <a href="#install">{t.installLink} <ArrowUpRight size={14}/></a></p></div>
      <section className="workflow shell">
        <h2>{t.workflow}</h2>
        <div className="steps">{t.steps.map(([title, text], i) => <article key={title}><span className="step-number">{i+1}</span><h3>{title}</h3><p>{text}</p></article>)}</div>
      </section>
      <section className="local-section">
        <div className="shell local-layout"><div><FolderOpen size={32}/><h2>{t.privacy}</h2></div><div><p>{t.privacyText}</p><p className="audio-spec">{t.spec}</p></div></div>
      </section>
      <section className="installation shell" id="install">
        <div><h2>{t.installTitle}</h2><ol>{t.installSteps.map(step => <li key={step}>{step}</li>)}</ol><a className="download" href={dmg}><ArrowDown size={22}/>{t.download}</a></div>
        <aside><h3>{t.blocked}</h3><p>{t.blockedText}</p><a href="https://support.apple.com/102445">{t.apple} <ArrowUpRight size={16}/></a><p className="intel-note">{t.intel}</p></aside>
      </section>
      <section className="faq shell"><h2>{t.questions}</h2><Accordion>{t.faqs.map(([question,answer]) => <AccordionItem key={question} value={question}><AccordionTrigger>{question}</AccordionTrigger><AccordionContent><p>{answer}</p></AccordionContent></AccordionItem>)}</Accordion><a href={`${repo}/blob/main/${{ru:'README.ru.md',es:'README.es.md',fr:'README.fr.md',en:'README.md'}[language]}`}>{t.readme} <ArrowUpRight size={16}/></a></section>
    </main>
    <footer className="shell"><div className="footer-brand"><Mic size={20}/><span>Voiceover Studio</span></div><div><a href={`${repo}/issues`}>{t.issues}</a><a href={`${repo}/blob/main/LICENSE`}>MIT License</a></div></footer>
  </div>;
}
