const { externalContractAddresses, saveDeployedAddress, loadDeployedAddress, verifyOnEtherscan } = require('./shared')

/* eslint-disable-next-line no-undef */
const CurrencyConverter = artifacts.require('CurrencyConverter')

module.exports = async function(deployer, network) {
	let externalAddresses

	if(network == 'kovan') {
		externalAddresses = externalContractAddresses.kovan
	} else {
		return
	}

	await deployer.deploy(CurrencyConverter,
		loadDeployedAddress(network, 'ideaTokenExchange'),
		externalAddresses.dai,
		externalAddresses.uniswapV2Router02,
		externalAddresses.weth)

	await verifyOnEtherscan(network, CurrencyConverter.address, 'CurrencyConverter')
	saveDeployedAddress(network, 'currencyConverter', CurrencyConverter.address)
}
