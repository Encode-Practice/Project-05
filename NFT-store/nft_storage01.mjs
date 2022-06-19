// Import the NFTStorage class and File constructor from the 'nft.storage' package
import { NFTStorage, File } from 'nft.storage'

// The 'mime' npm package helps us set the correct file type on our File objects
import mime from 'mime'

// The 'fs' builtin module on Node.js provides access to the file system
import fs from 'fs'

// The 'path' module provides helpers for manipulating filesystem paths
import path from 'path'

// Paste your NFT.Storage API key into the quotes:
const NFT_STORAGE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDcyMzYzOTIwOTM1MjNGNTA3OTAwRjk4NzdiODg4OUJhMTgyOGEzN2EiLCJpc3MiOiJuZnQtc3RvcmFnZSIsImlhdCI6MTY1NTUxMzY5NzAxMiwibmFtZSI6IkFQSTAxIn0.8iadgMNXENxLiwAISaMkv7MTO-LeSMmMy_6eU-eRfmY'

/**
  * Reads an image file from `imagePath` and stores an NFT with the given name and description.
  * @param {string} imagePath the path to an image file
  * @param {string} name a name for the NFT
  * @param {string} description a text description for the NFT
  */
async function storeNFT(imagePath, name, description) {
    // load the file from disk
    const image = await fileFromPath(imagePath)

    // create a new NFTStorage client using our API key
    const nftstorage = new NFTStorage({ token: NFT_STORAGE_KEY })

    // call client.store, passing in the image & metadata
    return nftstorage.store({
        image,
        name,
        description,
    })
}

/**
  * A helper to read a file from a location on disk and return a File object.
  * Note that this reads the entire file into memory and should not be used for
  * very large files. 
  * @param {string} filePath the path to a file to store
  * @returns {File} a File object containing the file content
  */
async function fileFromPath(filePath) {
    const content = await fs.promises.readFile(filePath)
    const type = mime.getType(filePath)
    return new File([content], path.basename(filePath), { type })
}

function get_nft(image) {
    const nft = {
        image: image,
        name: "Letter A",
        description: "letter A for dynamic nft",
        properties: {
          type: "image",
          origins: {
            http: "https://storageapi.fleek.co/c76c058e-c8d2-4089-b862-16e1f03eada8-bucket/Encode Project 5/letter_a.jpg"
          },
          authors: [{"name": "Team G"}]
          }
        }
    return nft
}
/**
 * The main entry point for the script that checks the command line arguments and
 * calls storeNFT.
 * 
 * To simplify the example, we don't do any fancy command line parsing. Just three
 * positional arguments for imagePath, name, and description
 */
async function main() {
    const address = "letter_a.jpg"
    const image = await fileFromPath(address)
    // create a new NFTStorage client using our API key
    const client = new NFTStorage({ token: NFT_STORAGE_KEY })
    const metadata = get_nft(image)
    const res = await client.store(metadata)
    console.log(res)
}

// Don't forget to actually call the main function!
// We can't `await` things at the top level, so this adds
// a .catch() to grab any errors and print them to the console.
main()
  .catch(err => {
      console.error(err)
      process.exit(1)
  })