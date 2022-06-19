import { NFTStorage } from 'nft.storage'
import fetch from "node-fetch"

// read the API key from an environment variable. You'll need to set this before running the example!
const API_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDcyMzYzOTIwOTM1MjNGNTA3OTAwRjk4NzdiODg4OUJhMTgyOGEzN2EiLCJpc3MiOiJuZnQtc3RvcmFnZSIsImlhdCI6MTY1NTUxMzY5NzAxMiwibmFtZSI6IkFQSTAxIn0.8iadgMNXENxLiwAISaMkv7MTO-LeSMmMy_6eU-eRfmY'

// For example's sake, we'll fetch an image from an HTTP URL.
// In most cases, you'll want to use files provided by a user instead.
async function getExampleImage() {
  const imageOriginUrl = "https://storageapi.fleek.co/c76c058e-c8d2-4089-b862-16e1f03eada8-bucket/Encode Project 5/letter_c.png"
  const r = await fetch(imageOriginUrl)
  if (!r.ok) {
    throw new Error(`error fetching image: [${r.statusCode}]: ${r.status}`)
  }
  else {
    console.log('fetched successfully')
  }
  return r.blob
}

async function storeExampleNFT() {
  //const image = await getExampleImage()
  const nft = {
    image: "ipfs://bafkreifrefmms2d74hjeuhqkzy65ejzp6ovp2jktep5zfbssnjtmdmgaxe",
    name: "Letter C",
    description: "letter c for dynamic nft",
    properties: {
      type: "image",
      origins: {
        ipfs: "ipfs://bafkreifrefmms2d74hjeuhqkzy65ejzp6ovp2jktep5zfbssnjtmdmgaxe",
        http: "https://bafkreifrefmms2d74hjeuhqkzy65ejzp6ovp2jktep5zfbssnjtmdmgaxe.ipfs.nftstorage.link/"
      },
      authors: [{"name": "Team G"}]
      }
    }

  const client = new NFTStorage({ token: API_KEY })
  const metadata = await client.store(nft)

  console.log('NFT data stored!')
  console.log('Metadata URI: ', metadata.url)
}

storeExampleNFT()