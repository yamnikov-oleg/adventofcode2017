function cycle<T>(list: T[], shift: number): T[] {
    shift = shift % list.length;
    const part1 = list.slice(0, shift);
    const part2 = list.slice(shift);
    return part2.concat(part1);
}

function tieKnot<T>(list: T[], pos: number, len: number): T[] {
    const shifted = cycle(list, pos);
    const shiftedTied = shifted.slice(0, len).reverse().concat(shifted.slice(len))
    const tied = cycle(shiftedTied, -pos);
    return tied;
}

class Hasher {
    private list: number[];
    private position: number;
    private skip: number;

    constructor(listLen: number) {
        this.list = Array.from(Array(listLen).keys(), (_, i) => i);
        this.position = 0;
        this.skip = 0;
    }

    get result(): number[] {
        return this.list;
    }

    applyKnot(len: number) {
        this.list = tieKnot(this.list, this.position, len);
        this.position = this.position + this.skip + len;
        this.skip++;
    }
}

function encodeASCII(input: string): number[] {
    const bytes = [];
    for (const char of input) {
        const code = char.charCodeAt(0);
        if (code <= 255) {
            bytes.push(code);
        } else {
            throw new Error("Tiing hasher only supports ASCII string");
        }
    }
    return bytes;
}

function hash(input: string): number[] {
    const MAGIC_SUFFIX = [17, 31, 73, 47, 23];
    const ROUNDS = 64;
    const HASHER_LIST_LEN = 256;
    const SPARSE_CHUNK_SIZE = 16;

    const lengths = encodeASCII(input).concat(MAGIC_SUFFIX);
    const hasher = new Hasher(HASHER_LIST_LEN);
    for (let round = 0; round < ROUNDS; round++) {
        for (const len of lengths) {
            hasher.applyKnot(len);
        }
    }

    let sparseHash = hasher.result;
    const denseHash = [];
    while (sparseHash.length > 0) {
        const chunk = sparseHash.slice(0, SPARSE_CHUNK_SIZE);
        sparseHash = sparseHash.slice(SPARSE_CHUNK_SIZE);
        denseHash.push(chunk.reduce((a, b) => a ^ b));
    }

    return denseHash;
}

function bytesToHex(bytes: number[]): string {
    let hex = "";
    for (const byte of bytes) {
        if (byte < 16) {
            hex += '0' + byte.toString(16);
        } else {
            hex += byte.toString(16);
        }
    }
    return hex;
}

enum Bit { Free, Set }

class Bitmap {
    readonly width: number;
    readonly height: number;
    private map: Bit[];

    constructor(width: number, height: number) {
        this.width = width;
        this.height = height;
        this.map = Array.from(Array(width * height), _ => Bit.Free);
    }

    getBit(i: number, j: number): Bit {
        if (i >= this.height || j >= this.width) {
            throw new Error(`Index ${i}, ${j} out of bounds ${this.width}x${this.height}`)
        }

        return this.map[i * this.width + j];
    }

    setBit(i: number, j: number, b: Bit) {
        if (i >= this.height || j >= this.width) {
            throw new Error(`Index ${i}, ${j} out of bounds ${this.width}x${this.height}`)
        }

        this.map[i * this.width + j] = b;
    }

    *bits(): IterableIterator<[Bit, number, number]> {
        for (let i = 0; i < this.height; i++) {
            for (let j = 0; j < this.width; j++) {
                yield [this.getBit(i, j), i, j];
            }
        }
    }
}

class CoordSet extends Bitmap {
    has(i: number, j: number): boolean {
        return this.getBit(i, j) === Bit.Set;
    }

    add(i: number, j: number) {
        this.setBit(i, j, Bit.Set);
    }

    delete(i: number, j: number) {
        this.setBit(i, j, Bit.Free);
    }
}

function byteToBits(byte: number): Bit[] {
    const bits = [];
    for (let i = 0; i < 8; i++) {
        if (byte % 2 == 0) {
            bits.push(Bit.Free);
        } else {
            bits.push(Bit.Set);
        }

        byte = Math.floor(byte / 2);
    }
    return bits.reverse();
}

function generateBitmap(key: string): Bitmap {
    const bitmap = new Bitmap(128, 128);

    for (let i = 0; i < 128; i++) {
        const hashBytes = hash(`${key}-${i}`);
        const hashBits = [].concat(...hashBytes.map(byteToBits));
        for (let j = 0; j < 128; j++) {
            bitmap.setBit(i, j, hashBits[j]);
        }
    }

    return bitmap;
}

function walkRegion(bitmap: Bitmap, oi: number, oj: number, visited: CoordSet) {
    let lastPass = [[oi, oj]];
    while (true) {
        const thisPass = [];
        for (const [i, j] of lastPass) {
            const neighbours = [[i + 1, j], [i - 1, j], [i, j + 1], [i, j - 1]];
            for (const [ni, nj] of neighbours) {
                if (ni < 0 || ni >= bitmap.height) continue;
                if (nj < 0 || nj >= bitmap.width) continue;
                if (bitmap.getBit(ni, nj) === Bit.Free) continue;
                if (visited.has(ni, nj)) continue;

                thisPass.push([ni, nj]);
            }
        }

        if (thisPass.length === 0) break;

        for (const [i, j] of thisPass) {
            visited.add(i, j);
        }
        lastPass = thisPass;
    }
}

function main() {
    if (process.argv.length < 3) {
        console.log("Bitmap generation key is required");
        process.exit(1);
    }

    const key = process.argv[2];
    const bitmap = generateBitmap(key);

    let countSet = 0;
    for (const [bit, i, j] of bitmap.bits()) {
        if (bit === Bit.Set) countSet++;
    }
    console.log(`Set bits: ${countSet}`);

    let countRegions = 0;
    const visited = new CoordSet(128, 128);
    for (const [bit, i, j] of bitmap.bits()) {
        if (bit === Bit.Free || visited.has(i, j)) {
            continue;
        }

        countRegions++;
        walkRegion(bitmap, i, j, visited);
    }
    console.log(`Regions: ${countRegions}`);
}

main();
