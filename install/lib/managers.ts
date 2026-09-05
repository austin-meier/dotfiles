import type { Command } from './exec.ts';

export type Manager = 'brew' | 'apt' | 'dnf' | 'pacman' | 'winget' | 'cargo';

export type Source = {
   readonly manager: Manager;
   readonly packages: readonly string[];
   readonly args?: readonly string[];
};

const RECIPES: Record<Manager, (source: Source) => Command> = {
   brew: ({ packages, args = [] }) => ({
      bin: 'brew',
      args: ['install', ...args, ...packages],
   }),

   apt: ({ packages, args = [] }) => ({
      bin: 'apt-get',
      args: ['install', '-y', ...args, ...packages],
      sudo: true,
   }),

   dnf: ({ packages, args = [] }) => ({
      bin: 'dnf',
      args: ['install', '-y', ...args, ...packages],
      sudo: true,
   }),

   pacman: ({ packages, args = [] }) => ({
      bin: 'pacman',
      args: ['-S', '--needed', '--noconfirm', ...args, ...packages],
      sudo: true,
   }),

   /* winget takes one --id per invocation, so multi-package sources are split
      by the caller via installCommands. 0x8A15002B is "already installed", which
      is success for our purposes. */
   winget: ({ packages, args = [] }) => ({
      bin: 'winget',
      okExitCodes: [-1978335189],
      args: [
         'install',
         '--id',
         packages[0] ?? '',
         '--exact',
         '--silent',
         '--accept-source-agreements',
         '--accept-package-agreements',
         ...args,
      ],
   }),

   cargo: ({ packages, args = [] }) => ({
      bin: 'cargo',
      args: ['install', '--locked', ...args, ...packages],
   }),
};

export const installCommands = (source: Source): readonly Command[] =>
   source.manager === 'winget'
      ? source.packages.map((pkg) => RECIPES.winget({ ...source, packages: [pkg] }))
      : [RECIPES[source.manager](source)];
