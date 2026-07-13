/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',            // fully static — client-only, deploys anywhere
  images: { unoptimized: true },
  trailingSlash: true,
};
export default nextConfig;
