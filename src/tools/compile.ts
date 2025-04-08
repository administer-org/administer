import fs from 'fs-extra';
import path from 'path';
import { convertLuaFileToJson } from './i18n_builder';

async function compileLocales() {
    const localesDir = path.join(__dirname, '../Server/Core/Locales');
    const outputDir = path.join(__dirname, '../../locales');

    await fs.ensureDir(outputDir);
    const fileNames = await fs.readdir(localesDir);

    for (const file of fileNames) {
        if (file.endsWith('.luau')) {
            const langCode = path.basename(file, '.luau');
            const content = await convertLuaFileToJson(await fs.readFile(path.join(localesDir, file), 'utf-8'));

            const langDir = path.join(outputDir, langCode);
            const outputPath = path.join(langDir, `${langCode}.json`);

            await fs.ensureDir(langDir);
            await fs.writeFile(outputPath, JSON.stringify(content, null, 2));

            console.log(`Converted ${file} to ${outputPath}`);
        }
    }
}

compileLocales().catch(err => {
    console.error("Error during compilation:", err);
});
