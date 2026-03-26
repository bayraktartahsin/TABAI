/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: "export",
  distDir: ".next-build",
  images: {
    unoptimized: true
  }
};

export default nextConfig;
