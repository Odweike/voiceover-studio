import type { Metadata } from 'next';
import { Onest } from 'next/font/google';
import './globals.css';

const onest = Onest({ variable: '--font-onest', subsets: ['latin', 'cyrillic'], display: 'swap' });
export const metadata: Metadata = {
  metadataBase: new URL('https://voiceover-studio.excomper.chatgpt.site'),
  title: 'Voiceover Studio — озвучка по репликам для macOS',
  description: 'Бесплатное приложение для записи озвучки по сценарию. Записывайте реплики, выбирайте лучшие дубли и забирайте WAV. macOS 14.4+, Apple Silicon и Intel.',
  icons: { icon: '/icon.png', apple: '/icon.png' },
};
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="ru"><body className={onest.variable}>{children}</body></html>;
}
