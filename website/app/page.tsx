'use client';

import Image from 'next/image';
import { useState } from 'react';
import { ArrowDown, ArrowUpRight, Check, Mic, FolderOpen } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from '@/components/ui/accordion';

const repo = 'https://github.com/Odweike/voiceover-studio';
const dmg = `${repo}/releases/download/v0.2.0/Voiceover-Studio-0.2.0-universal.dmg`;
const words = {
  ru: {
    skip: 'К содержимому', install: 'Установка', headline: <>Озвучка.<br/>Реплика за репликой.</>,
    intro: 'Откройте сценарий, запишите каждую реплику и выберите лучший дубль. Готовые WAV-файлы — для вашего монтажа.',
    download: 'Скачать для macOS', free: 'Бесплатно · без регистрации · открытый код',
    compatibility: 'macOS 14.4+ · Apple Silicon и Intel', version: 'Версия 0.2.0 · универсальный DMG',
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
    readme: 'Документация', issues: 'Сообщить об ошибке', author: 'Сделано Максимом Мариным для своего рабочего процесса. Теперь — для всех.',
    intel: 'Проверено на Apple Silicon. Intel-сборка включена; на физическом Intel Mac этот выпуск пока не тестировался.',
  },
  en: {
    skip: 'Skip to content', install: 'Install', headline: <>Voiceovers.<br/>One line at a time.</>,
    intro: 'Open your script, record each line and choose your best take. Get individual WAV files, ready for your edit.',
    download: 'Download for macOS', free: 'Free · no account · open source',
    compatibility: 'macOS 14.4+ · Apple Silicon & Intel', version: 'Version 0.2.0 · universal DMG',
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
    faqs: [ ['Is it free?', 'Yes. The app and source code are free under the MIT license. No subscription, account or take limits.'], ['Can I use any Excel workbook?', 'Use a simple single-sheet XLSX: headers in row 1, Russian text in D, English in E. Formulas are not calculated. The README has the full format and a ready-to-use JSON sample.'], ['Is this an audio editor?', 'No. Voiceover Studio helps you record voiceovers and select takes. Trim, process and edit the audio in your preferred editor.'], ['Where are my recordings?', 'By default, under Movies / Voiceover Studio / Projects. The “Показать проект” button opens the folder. Back up the entire folder to preserve your work.'] ],
    readme: 'Documentation', issues: 'Report a bug', author: 'Made by Maxim Marin for his own workflow. Now shared with everyone.',
    intel: 'Tested on Apple Silicon. An Intel build is included; this release has not yet been tested on a physical Intel Mac.',
  },
};

export default function Home() {
  const [language, setLanguage] = useState<'ru' | 'en'>('ru');
  const t = words[language];
  return <div lang={language}>
    <a className="skip" href="#main">{t.skip}</a>
    <header className="site-header shell">
      <a href="#main" className="brand" aria-label="Voiceover Studio"><Image unoptimized src="/icon.png" width="40" height="40" alt=""/>Voiceover Studio</a>
      <nav aria-label={language === 'ru' ? 'Навигация' : 'Navigation'}>
        <a href="#install" className="nav-install">{t.install}</a>
        <a href={repo} aria-label="GitHub"><ArrowUpRight size={20}/><span>GitHub</span></a>
        <div className="language" aria-label="Language">
          {(['ru','en'] as const).map(lang => <Button key={lang} variant="ghost" size="sm" aria-pressed={language === lang} onClick={() => { setLanguage(lang); document.documentElement.lang = lang; }}>{lang.toUpperCase()}</Button>)}
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
          <div className="screenshot-window"><Image unoptimized src="/app-screenshot.png" alt={t.caption} width="1120" height="760" priority/></div>
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
      <section className="faq shell"><h2>{t.questions}</h2><Accordion>{t.faqs.map(([question,answer]) => <AccordionItem key={question} value={question}><AccordionTrigger>{question}</AccordionTrigger><AccordionContent><p>{answer}</p></AccordionContent></AccordionItem>)}</Accordion><a href={`${repo}/blob/main/${language === 'ru' ? 'README.ru.md' : 'README.md'}`}>{t.readme} <ArrowUpRight size={16}/></a></section>
    </main>
    <footer className="shell"><div className="footer-brand"><Mic size={20}/><span>Voiceover Studio</span></div><p>{t.author}</p><div><a href={`${repo}/issues`}>{t.issues}</a><a href={`${repo}/blob/main/LICENSE`}>MIT License</a></div></footer>
  </div>;
}
