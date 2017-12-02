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
        rl.on('line', onLine);
        rl.on('close', resolve);
    });
}

async function main() {
    const path = process.argv[2];

    let checksum = 0;

    try {
        await readLines(path, (line) => {
            const values = line.trim().split('\t').map(Number);
            const max = Math.max(...values);
            const min = Math.min(...values);
            checksum += max - min;
        });
    } catch (error) {
        console.error(error.toString());
        return;
    }

    console.info(`Checksum: ${checksum}`);
}

main();
