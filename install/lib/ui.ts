const CODES = {
   green: '\x1b[38;2;152;190;101m',
   blue: '\x1b[38;2;81;175;239m',
   yellow: '\x1b[38;2;236;190;123m',
   red: '\x1b[38;2;255;108;107m',
   grey: '\x1b[38;2;91;98;104m',
   bold: '\x1b[1m',
   reset: '\x1b[0m',
} as const;

/* Older Windows consoles render escapes literally; NO_COLOR is the standard opt-out. */
const colored = process.stdout.isTTY === true && process.env.NO_COLOR === undefined;

const paint = (code: keyof typeof CODES, text: string): string =>
   colored ? `${CODES[code]}${text}${CODES.reset}` : text;

export const header = (text: string): void => console.log(`\n${paint('bold', text)}`);
export const info = (text: string): void => console.log(`${paint('blue', '  ')} ${text}`);
export const success = (text: string): void => console.log(`${paint('green', '  ')} ${text}`);
export const warn = (text: string): void => console.log(`${paint('yellow', '  ')} ${text}`);
export const skip = (text: string): void => console.log(`${paint('grey', '  -')} ${paint('grey', text)}`);
export const plan = (text: string): void => console.log(`${paint('grey', '  →')} ${paint('grey', text)}`);
export const fail = (text: string): void => console.error(`${paint('red', '  ')} ${text}`);
