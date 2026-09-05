import { spawnSync } from 'node:child_process';
import { Err, Ok, type Result } from './result.ts';
import { which } from './platform.ts';
import * as ui from './ui.ts';

export type Command = {
   readonly bin: string;
   readonly args: readonly string[];
   /* Prefixed with sudo on unix; ignored on Windows, which has no equivalent. */
   readonly sudo?: boolean;
   /* Non-zero exits that still mean success, e.g. winget's "already installed". */
   readonly okExitCodes?: readonly number[];
};

export const render = (command: Command): string =>
   [command.sudo === true ? 'sudo' : undefined, command.bin, ...command.args]
      .filter((part) => part !== undefined)
      .join(' ');

/* Swappable so --dry-run prints the whole plan without touching the machine.
   `probe` is the only member that executes under --dry-run, so it must only ever
   be handed read-only commands. Anything that mutates goes through run/tryRun. */
export interface Runner {
   readonly dryRun: boolean;
   readonly run: (command: Command) => Result<void, string>;
   readonly tryRun: (command: Command) => void;
   readonly probe: (command: Command) => Result<string, string>;
}

export type Spawn = (command: Command, capture: boolean) => Result<string, string>;

const spawn = (command: Command, capture: boolean): Result<string, string> => {
   const elevate = command.sudo === true && process.platform !== 'win32';
   const bin = elevate ? 'sudo' : command.bin;
   const args = elevate ? [command.bin, ...command.args] : [...command.args];

   /* Resolve through our own PATH walk so PATHEXT works without shell: true,
      which would force us to hand-quote every argument. */
   const result = spawnSync(which(bin) ?? bin, args, {
      stdio: capture ? 'pipe' : 'inherit',
      encoding: 'utf8',
   });

   if (result.error !== undefined) {
      return Err(`${render(command)}: ${result.error.message}`);
   }
   if (result.status !== 0 && !(command.okExitCodes ?? []).includes(result.status ?? -1)) {
      const detail = capture && result.stderr ? `: ${result.stderr.trim()}` : '';
      return Err(`${render(command)} exited ${result.status}${detail}`);
   }
   return Ok(capture ? result.stdout.trim() : '');
};

/* `exec` is injectable so the dry-run contract can be asserted in tests. */
export const createRunner = (dryRun: boolean, exec: Spawn = spawn): Runner => ({
   dryRun,

   run: (command) => {
      if (dryRun) {
         ui.plan(render(command));
         return Ok(undefined);
      }
      const result = exec(command, false);
      return result.tag === 'ok' ? Ok(undefined) : result;
   },

   /* Mutating, but a failure is expected and fine (removing something absent). */
   tryRun: (command) => {
      if (dryRun) {
         ui.plan(render(command));
         return;
      }
      exec(command, true);
   },

   /* Read-only. Runs for real under --dry-run so the printed plan is accurate. */
   probe: (command) => exec(command, true),
});
