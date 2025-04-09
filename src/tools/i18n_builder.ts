import fs from 'fs-extra';

function luaToJson(lua: string): any {
    let jsonString = lua
        .replace(/^return\s*/, '')
        .trim()
        .replace(/--.*/g, '');
        
    jsonString = jsonString
        .replace(/,(?=\s*[}\]])/g, '')
        .replace(/(['"])((?:\\.|(?!\1).)*?)\1/g, (match, quote, content) => {
        const escapedContent = content
            .replace(/\\/g, '\\\\')
            .replace(/"/g, '\\"');
        return `"${escapedContent}"`;
    });

    jsonString = jsonString
        .replace(/([{,]\s*)([a-zA-Z_]\w*)\s*=/g, '$1"$2" =')
        .replace(/\s*=\s*/g, ': ')
        .replace(/\["([^"]+)"\]\s*:/g, '"$1":')
        .replace(/\['([^']+)']\s*:/g, '"$1":');

    try {
        return JSON.parse(jsonString);
    } catch (error) {
        throw new Error(`Failed to convert Lua to JSON. Intermediate state: ${jsonString}. Error: ${error}`);
    }
}

function jsonToLua(jsonObj: { [key: string]: any }): string {
    return `return {\n${Object.entries(jsonObj)
        .map(([key, value]) => `["${key}"] = ${Array.isArray(value) ? `[${value.map(item => `"${item}"`).join(', ')}]` : typeof value === 'string' ? `"${value}"` : value}`)
        .join(',\n')}\n}`;
}

async function convertLuaFileToJson(luaContent: string): Promise<JSON> {
    try {
        if (!luaContent) throw new Error('Lua file is empty or could not be read.');
        const jsonObj = luaToJson(luaContent);

        if (Object.keys(jsonObj).length === 0) {
            throw new Error('Converted Lua object is empty.');
        }

        console.log(`Success!`);
        return jsonObj;
    } catch (err) {
        console.error('Error converting Lua file to JSON:', err);
        return  JSON.parse({"failed": true, "code": err})
    }
}

async function convertJsonFileToLua(jsonFilePath: string, luaFilePath: string): Promise<void> {
    try {
        const jsonContent = await fs.readFile(jsonFilePath, 'utf-8');

        if (!jsonContent) throw new Error('JSON file is empty or could not be read.');

        const jsonObj = JSON.parse(jsonContent);
        const luaContent = jsonToLua(jsonObj);
        await fs.writeFile(luaFilePath, luaContent);

        console.log(`Successfully converted JSON to Lua and saved to ${luaFilePath}`);
    } catch (err) {
        console.error('Error converting JSON file to Lua:', err);
    }
}

export { luaToJson, jsonToLua, convertLuaFileToJson, convertJsonFileToLua };

