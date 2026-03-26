import { cpSync, existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const outDir = join(root, ".next-build");
const deployDir = join(root, ".next");

if (!existsSync(outDir)) {
  throw new Error("Static export output not found at ./.next-build");
}

rmSync(deployDir, { recursive: true, force: true });
mkdirSync(deployDir, { recursive: true });
cpSync(outDir, deployDir, { recursive: true });

writeFileSync(
  join(deployDir, "_headers"),
  `/*
  Cache-Control: public, max-age=0, must-revalidate

/_next/static/*
  Cache-Control: public, max-age=31536000, immutable

/favicon.png
  Cache-Control: public, max-age=31536000, immutable

/apple-touch-icon.png
  Cache-Control: public, max-age=31536000, immutable

/icon-512.png
  Cache-Control: public, max-age=31536000, immutable
`,
);

console.log("Prepared .next for Cloudflare Pages deploy");
