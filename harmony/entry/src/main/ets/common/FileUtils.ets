/**
 * Safe file I/O utilities for HarmonyOS.
 *
 * Previously embedded in Index.ets as private methods on the @Component struct.
 * Extracted here for reuse across import/export flows.
 */
import fs from '@ohos.file.fs';
import util from '@ohos.util';

/**
 * Write a UTF-8 string to a file. Tries the fast path (direct string
 * write) first; falls back to encoding into an ArrayBuffer if the SDK
 * on this device rejects string content.
 */
export async function writeFileSafe(uri: string, content: string): Promise<void> {
  const file = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  try {
    try {
      fs.writeSync(file.fd, content);
    } catch (stringWriteError) {
      const encoder = new util.TextEncoder();
      const bytes: Uint8Array = encoder.encodeInto(content);
      fs.writeSync(file.fd, bytes.buffer);
    }
  } finally {
    fs.closeSync(file);
  }
}

/**
 * Read a file as a UTF-8 string. Tries `fs.readTextSync` first; if that
 * API is unavailable on this SDK, falls back to open + stat + read +
 * TextDecoder.
 */
export async function readFileSafe(uri: string): Promise<string> {
  try {
    return fs.readTextSync(uri);
  } catch (readTextError) {
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    try {
      const stat = fs.statSync(file.fd);
      const size: number = stat.size;
      const buffer: ArrayBuffer = new ArrayBuffer(size);
      fs.readSync(file.fd, buffer);
      const decoder = util.TextDecoder.create('utf-8');
      return decoder.decodeToString(new Uint8Array(buffer));
    } finally {
      fs.closeSync(file);
    }
  }
}
