import path from 'path';
import { promises as fs } from 'fs';
import type { NextApiRequest, NextApiResponse } from 'next'


export default async function handler(
    req: NextApiRequest,
    res: NextApiResponse ) {

    //Find the absolute path of the json directory
    const contractDirectory = path.join(process.cwd(), 'contracts/src');
    const fileContents = await fs.readFile(contractDirectory + '/lcValidator.hl', 'utf8');
    res.setHeader('Content-Type', 'text');
    res.send(fileContents);

}
