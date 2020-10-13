const fs = require('fs')
const shared = require('./shared')
const Web3 = require('web3')
const web3 = new Web3()

async function run() {
    const marketName = await shared.getInput('market name')
    const nameVerifierName = await shared.getInput('name of name verifier')
    const rawBaseCost = await shared.getInput('baseCost in dai')
    const rawPriceRise = await shared.getInput('priceRise in dai')
    const rawTokensPerInterval = await shared.getInput('tokens per interval')
    const rawTradingFee = await shared.getInput('trading fee in percent')
    const rawPlatformFee = await shared.getInput('platform fee in percent')

    console.log('------------------------------------------------------')

    const executionDate = await shared.getInput('execution date (DAY-MONTH-YEAR HOUR:MINUTE:SECOND) in UTC time')
    const network = await shared.getInput('network (mainnet / kovan)')
    const factoryAddress = shared.loadDeployedAddress(network, 'ideaTokenFactory')

    // End of input

    const nameVerifier = shared.loadDeployedAddress(network, nameVerifierName.charAt(0).toLowerCase() + nameVerifierName.slice(1))
    const baseCost = shared.toWei(rawBaseCost)
    const priceRise = shared.toWei(rawPriceRise)
    const tokensPerInterval = shared.toWei(rawTokensPerInterval)
    const tradingFee = shared.percentageFeeToFeeRate(rawTradingFee, 10000)
    const platformFee = shared.percentageFeeToFeeRate(rawPlatformFee, 10000)

    const executionTimestamp = shared.unixTimestampFromDateString(executionDate)

    const rawTimelock = fs.readFileSync('../build/contracts/DSPause.json')
    const rawTimelockJson = JSON.parse(rawTimelock)
    const timelockAbi = rawTimelockJson.abi
    const timelockAddress = shared.loadDeployedAddress(network, 'dsPause')

    const rawSpell = fs.readFileSync('../build/contracts/AddMarketSpell.json')
    const rawSpellJson = JSON.parse(rawSpell)
    const spellAbi = rawSpellJson.abi
    const spellAddress = shared.loadDeployedAddress(network, 'addMarketSpell')

    console.log('------------------------------------------------------')
    console.log('market name:', marketName)
    console.log('name verifier address:', nameVerifier)
    console.log('base cost:', baseCost.toString())
    console.log('price rise:', priceRise.toString())
    console.log('tokens per interval:', tokensPerInterval.toString())
    console.log('trading fee rate:', tradingFee.toString())
    console.log('platform fee rate:', platformFee.toString())
    console.log('execution timestamp:', executionTimestamp.toString())
    console.log('timelock address:', timelockAddress)
    console.log('spell address:', spellAddress)
    console.log('factory address:', factoryAddress)
    console.log('network:', network)

    console.log('')
    await shared.getInput('press enter to continue')

    const spellCall = web3.eth.abi.encodeFunctionCall(
        shared.getFunctionABI(spellAbi, 'execute'),
        [
            factoryAddress,
            marketName,
            nameVerifier,
            baseCost.toString(),
            priceRise.toString(),
            tokensPerInterval.toString(),
            tradingFee.toString(),
            platformFee.toString()
        ]
    )

    console.log(spellCall)

}



run()