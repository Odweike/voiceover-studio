import type { NextConfig } from 'next';

const nextConfig: NextConfig = process.env.SELF_HOSTED === '1'
  ? { output: 'export', basePath: '/voiceOver', trailingSlash: true }
  : {};

export default nextConfig;
