import { existsSync, readFileSync } from 'node:fs';
import { delimiter, join } from 'node:path';
import { Err, Ok, type Result, tryCatch } from './result.ts';

export type Platform = 'darwin' | 'debian' | 'fedora' | 'arch' | 'windows';

export const PLATFORMS = ['darwin', 'debian', 'fedora', 'arch', 'windows'] as const;

export const isPlatform = (value: string): value is Platform =>
   (PLATFORMS as readonly string[]).includes(value);

export const isWindows = (platform: Platform): boolean => platform === 'windows';

/* A WSL2 distro detects as its own linux platform (debian/fedora/arch), which is
   correct. This only affects reporting and the WSL health checks. */
export const isWsl = (): boolean => {
   if (process.platform !== 'linux') return false;
   if (process.env.WSL_DISTRO_NAME !== undefined) return true;

   const version = tryCatch(() => readFileSync('/proc/version', 'utf8'));
   return version.tag === 'ok' && version.value.toLowerCase().includes('microsoft');
};

/* Anything under a drive mount is on the Windows side of the 9p boundary. */
export const onWindowsDrive = (path: string): boolean => /^\/mnt\/[a-z]\//.test(path);

/* Own implementation rather than shelling out: this runs before anything is
   installed, and it has to behave the same under sh, Git Bash, and PowerShell. */
export const which = (bin: string): string | undefined => {
   const extensions =
      process.platform === 'win32' ? (process.env.PATHEXT ?? '.EXE;.CMD;.BAT').split(';') : [''];

   return (process.env.PATH ?? '')
      .split(delimiter)
      .filter((dir) => dir !== '')
      .flatMap((dir) => extensions.map((extension) => join(dir, bin + extension)))
      .find((candidate) => existsSync(candidate));
};

export const installed = (bin: string): boolean => which(bin) !== undefined;

/* Tools installed earlier in this same run land in directories the process PATH
   was built without. Without this, a fresh machine installs rustup and then
   fails to find cargo two programs later. */
export const addToPath = (dir: string): void => {
   const current = (process.env.PATH ?? '').split(delimiter);
   if (existsSync(dir) && !current.includes(dir)) {
      process.env.PATH = [dir, ...current].join(delimiter);
   }
};

const LINUX_PROBES = [
   { bin: 'apt-get', platform: 'debian' },
   { bin: 'dnf', platform: 'fedora' },
   { bin: 'pacman', platform: 'arch' },
] as const satisfies readonly { bin: string; platform: Platform }[];

export const detect = (): Result<Platform, string> => {
   if (process.platform === 'darwin') return Ok('darwin');
   if (process.platform === 'win32') return Ok('windows');
   if (process.platform !== 'linux') return Err(`unsupported platform: ${process.platform}`);

   const probe = LINUX_PROBES.find(({ bin }) => installed(bin));

   return probe
      ? Ok(probe.platform)
      : Err('unsupported linux distro (needs one of apt-get, dnf, pacman)');
};
