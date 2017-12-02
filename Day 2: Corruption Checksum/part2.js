const fs = require('fs');
const readline = require('readline');
const { promisify } = require('util');

function readLines(path, onLine) {
    return new Promise((resolve, reject) => {
        const stream = fs.createReadStream(path);
        const rl = readline.createInterface({
            input: stream,
            crlfDelay: Infinity,
        });

        stream.on('error', reject);

        let lineIndex = 0;
        rl.on('line', (line) => {
            try {
                onLine(line, lineIndex);
                lineIndex++;
            } catch (error) {
                reject(error);
                rl.close();
            }
        });
        rl.on('close', resolve);
    });
}

function lineChecksum(values) {
    const valuesSet = new Set(values);
    const sorted = [...values].sort((a, b) => a - b);
    const maxValue = sorted[sorted.length - 1];

    const checksums = []
    for (const num of sorted) {
        for (let i = 2; num * i <= maxValue; i++) {
            if (valuesSet.has(num * i)) {
                checksums.push(i);
            }
        }
    }

    if (checksums.length != 1) {
        throw new Error(
            `Expected 1 possible checksum for a line, ` +
            `found ${checksums.length}: ` +
            checksums.toString(),
        );
    }

    return checksums[0];
}

async function main() {
    const path = process.argv[2];

    let checksum = 0;

    try {
        await readLines(path, (line, index) => {
            try {
                const values = line.trim().split('\t').map(Number);
                checksum += lineChecksum(values);
            } catch (error) {
                console.error(`Error while processing line ${index + 1}: ${error.toString()}`);
            }
        });
    } catch (error) {
        console.error(error.toString());
        return;
    }

    console.info(`Checksum: ${checksum}`);
}

main();
