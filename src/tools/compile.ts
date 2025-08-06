import fs from 'fs-extra';
import path from 'path';

import { convertLuaFileToJson, convertJsonFileToLua } from './i18n_builder';

async function compileLocales() {
    const localesDir = path.join(__dirname, '../Server/Core/Locales');
    const outputDir = path.join(__dirname, '../../locales');

    await fs.ensureDir(outputDir);
    const fileNames = await fs.readdir(localesDir);

    for (const file of fileNames) {
        if (file.endsWith('.luau')) {
            const langCode = path.basename(file, '.luau');
            const filePath = path.join(localesDir, file);
            const luaContent = await fs.readFile(filePath, 'utf-8');
            const jsonData = await convertLuaFileToJson(luaContent);

            const langDir = path.join(outputDir, langCode);
            const outputPath = path.join(langDir, `${langCode}.json`);

            await fs.ensureDir(langDir);
            await fs.writeFile(outputPath, JSON.stringify(jsonData, null, 2), 'utf-8');

            console.log(`done ${filePath} -> ${outputPath}`);
        }
    }
}

async function compileLuau() {
    const inputDir = path.join(__dirname, '../../locales');
    const outputDir = path.join(__dirname, '../Server/Core/Locales');

    await fs.ensureDir(outputDir);
    const files = await fs.readdir(inputDir);

    for (const fileName of files) {
        if (!fileName.endsWith('.json')) {
            console.log(`Skipping non-json file: ${fileName}`);
            continue;
        }

        const langCode = path.basename(fileName, '.json');
        const jsonPath = path.join(inputDir, fileName);
        const luaPath = path.join(outputDir, `${langCode}.luau`);

        console.log(`Processing ${jsonPath} -> ${luaPath}`);

        await convertJsonFileToLua(jsonPath, luaPath);
    }
}

compileLuau()
    .catch((err) => console.error("Failed", err));
