import type { Runner } from './exec.ts';

export type Distro = {
   readonly name: string;
   readonly state: string;
   readonly version: number;
   readonly default: boolean;
};

/* `wsl --list --verbose` emits UTF-16LE unless WSL_UTF8=1, and older builds
   ignore that variable, so strip the interleaved nulls either way. Matched with a
   regex per line rather than split on whitespace, because the leading `*` marker
   for the default distro is optional. */
export const parseDistros = (output: string): readonly Distro[] =>
   output
      .replace(/\u0000/g, '')
      .split(/\r?\n/)
      .map((line) => /^\s*(\*?)\s*(\S+)\s+(\S+)\s+(\d+)\s*$/.exec(line))
      .filter((match) => match !== null)
      .map((match) => ({
         default: match[1] === '*',
         name: match[2] ?? '',
         state: match[3] ?? '',
         version: Number(match[4]),
      }))
      /* Drops the NAME/STATE/VERSION header, whose last column isn't a number. */
      .filter((distro) => Number.isFinite(distro.version));

export const version2 = (distros: readonly Distro[]): readonly Distro[] =>
   distros.filter((distro) => distro.version === 2);

export const detect = (runner: Runner): readonly Distro[] => {
   const listed = runner.probe({ bin: 'wsl.exe', args: ['--list', '--verbose'] });
   return listed.tag === 'ok' ? parseDistros(listed.value) : [];
};
