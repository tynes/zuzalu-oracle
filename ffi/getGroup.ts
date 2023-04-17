import { ethers } from 'ethers'
import fetch from 'node-fetch'
import { deserializeSemaphoreGroup } from '@pcd/semaphore-group-pcd'

const url = 'https://api.pcd-passport.com/semaphore/1'
const coder = ethers.AbiCoder.defaultAbiCoder()
const abi = ['uint256', 'string', 'uint256[]', 'uint256', 'uint256']

;(async () => {
    const response = await fetch(url)
    const json = await response.json()

    const group = deserializeSemaphoreGroup(json)

    const data = [
        parseInt(json.id, 10),
        json.name,
        json.members.slice(0, 1),
        json.depth,
        group.root.toString()
    ]

    const encoded = coder.encode(abi, data)
    process.stdout.write(encoded)
})()
