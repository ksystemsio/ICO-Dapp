import '../stylesheets/app.css'
import { default as Web3 } from 'web3'
import { default as contract } from 'truffle-contract'
import $ from 'jquery'
import ether from '../../node_modules/zeppelin-solidity/test/helpers/ether'

const BigNumber = web3.BigNumber

import logiq_artifacts from '../../build/contracts/LogiqTokenCrowdsale.json'
import coin_artifacts from '../../build/contracts/LogiqToken.json'
import _ from 'lodash'

var LogiqTokenCrowdsale = contract(logiq_artifacts)
var LogiqToken = contract(coin_artifacts)
var accounts
var account
var contract_address = ''

function timeConverter(UNIX_timestamp){
  let a = new Date(UNIX_timestamp * 1000);
  let months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  let year = a.getFullYear()
  let month = months[a.getMonth()]
  let date = a.getDate()
  let hour = a.getHours() < 10 ? '0' + a.getHours() : a.getHours()
  let min = a.getMinutes() < 10 ? '0' + a.getMinutes() : a.getMinutes()
  let sec = a.getSeconds() < 10 ? '0' + a.getSeconds() : a.getSeconds()
  let time = date + ' ' + month + ' ' + year + ' ' + hour + ':' + min + ':' + sec
  return time
}

window.App = {
  start: function () {
    var self = this
    contract_address = document.getElementById('address').value

    // Bootstrap the Logiq abstraction for Use.
    LogiqTokenCrowdsale.setProvider(web3.currentProvider)
    LogiqToken.setProvider(web3.currentProvider)

    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function (err, accs) {
      if (err != null) {
        alert('There was an error fetching your accounts.')
        return
      }
      if (accs.length == 0) {
        alert('Couldn\'t get any accounts! Make sure your Ethereum client is configured correctly.')
        return
      }

      accounts = accs
      account = accounts[0]
      document.getElementById('account').value = account

      self.refreshBalance()
      self.infoAboutCrowdsale()
    })
  },
  setStatus: function (message) {
    var status = document.getElementById('status')
    status.innerHTML = message
  },
  refreshBalance: function () {
    var self = this
    if (contract_address) {
      self.getBalance(account).then(function (data) {
        var balance_confirmed_element = document.getElementById('balance_confirmed')
        balance_confirmed_element.innerHTML = data.logiq
        var whitelisted_element = document.getElementById('whitelisted')
        whitelisted_element.innerHTML = data.whitelisted
        var balance_element = document.getElementById('balance')
        balance_element.innerHTML = data.eth
        self.getEthPrice()
      })
    }
  },
  buyTokens: function () {
    var self = this
    var amount = ether(parseFloat(document.getElementById('amount').value))
    var beneficiary = document.getElementById('beneficiary').value

    this.setStatus('Initiating transaction... (please wait)')

    var meta
    if (contract_address) {
      LogiqTokenCrowdsale.at(contract_address).then(function (instance) {
        meta = instance
        console.log(amount)
        return meta.buyTokens(beneficiary, {from: account, value: amount})
      }).then(function () {
        self.setStatus('Transaction complete!')
        self.refreshBalance()
      }).catch(function (e) {
        console.log(e)
        self.setStatus('Error sending coin; see log.')
      })
    }
  },
  whitelistAddress: function () {
    var self = this
    var whitelist = document.getElementById('whitelist').value
    if (contract_address) {
      LogiqTokenCrowdsale.at(contract_address).then(function (instance) {
        return instance.whitelistAddress(whitelist, {from: account})
      }).then(function () {
        self.setStatus('Transaction complete!')
      }).catch(function (e) {
        console.log(e)
        self.setStatus('Error sending coin; see log.')
      })
    }
  },
  refundTokens: function () {
    var self = this
    if (contract_address) {
      LogiqTokenCrowdsale.at(contract_address).then(function (instance) {
        return instance.refundTokens({from: account})
      }).then(function () {
        self.setStatus('Transaction complete!')
      }).catch(function (e) {
        console.log(e)
        self.setStatus('Error sending coin; see log.')
      })
    }
  },
  transferTokenOwnership: function () {
    var self = this
    if (contract_address) {
      LogiqTokenCrowdsale.at(contract_address).then(function (instance) {
        return instance.refundTokens({from: account})
      }).then(function () {
        self.setStatus('Transaction complete!')
      }).catch(function (e) {
        console.log(e)
        self.setStatus('Error sending coin; see log.')
      })
    }
  },
  refundTokensForAddress: function () {
    var self = this
    var refund_address = document.getElementById('refund').value
    if (contract_address) {
      LogiqTokenCrowdsale.at(contract_address).then(function (instance) {
        return instance.refundTokensForAddress(refund_address, {from: account})
      }).then(function () {
        self.setStatus('Transaction complete!')
      }).catch(function (e) {
        console.log(e)
        self.setStatus('Error sending coin; see log.')
      })
    }
  },
  getAddresses: function () {
    var self = this
    if (contract_address) {
      LogiqTokenCrowdsale.at(contract_address).then(function (instance) {
        return instance.getAddresses({from: account})
      }).then(function (addresses) {
        var addresses_element = document.getElementById('addresses')
        var res = []
        var whitelisted_element = document.getElementById('addresses')
        whitelisted_element.value = ''
        _(addresses).forEach(function (address) {
          self.getBalance(address).then(function (data) {
            res.push(data)
            whitelisted_element.value = whitelisted_element.value + '\n' + 'address: ' + data.address + ', eth:' + data.eth + ', logiq:' + data.logiq + ', whitelisted:' + data.whitelisted + '\n'
          })
          self.setStatus('Transaction complete!')
        })

      }).catch(function (e) {
        console.log(e)
        self.setStatus('Error sending coin; see log.')
      })
    }
  },
  getBalance: async function (address) {
    var eth_balance = 0
    var logiq_balance = 0
    var whitelisted = false

    if (contract_address) {
      const LogiqTokenCrowdsaleInstance = await LogiqTokenCrowdsale.at(contract_address)
      const contributorValues = await LogiqTokenCrowdsaleInstance.contributors.call(address)
      eth_balance = contributorValues[0].valueOf() / ether(1)
      whitelisted = contributorValues[1].valueOf()
      const token = await LogiqTokenCrowdsaleInstance.token.call()
      const LogiqTokenInstance = await LogiqToken.at(token)
      const balance = await LogiqTokenInstance.balanceOf(address)
      logiq_balance = balance / ether(1)
    }
    return {'address': address, 'eth': eth_balance, 'logiq': logiq_balance, 'whitelisted': whitelisted}
  },
  getEthPrice: function () {
    $.ajax('https://api.coinmarketcap.com/v1/ticker/ethereum/',
      {
        'dataType': 'json', 'cache': 'false', 'data': {'t': Date.now()}
      }).done(function (result) {
      let ethereumPrice = Number(result[0].price_usd)
      document.getElementById('ethereumPrice').innerHTML = ethereumPrice
    })
  },
  infoAboutCrowdsale: function () {
    if (contract_address) {
      LogiqTokenCrowdsale.at(contract_address).tokensSold.call().then(function (res) {
        document.getElementById('tokensSold').innerHTML = res
      })
      LogiqTokenCrowdsale.at(contract_address).token.call().then(function (res) {
        document.getElementById('token').innerHTML = res
      })
      LogiqTokenCrowdsale.at(contract_address).buyPrice.call().then(function (res) {
        document.getElementById('buyPrice').innerHTML = res + ' LOGIQ'
      })
      LogiqTokenCrowdsale.at(contract_address).softcap.call().then(function (res) {
        document.getElementById('softcap').innerHTML = res / ether(1)
      })
      LogiqTokenCrowdsale.at(contract_address).hardcap.call().then(function (res) {
        document.getElementById('hardcap').innerHTML = res / ether(1)
      })
      LogiqTokenCrowdsale.at(contract_address).crowdSaleStatus.call().then(function (res) {
        document.getElementById('crowdSaleStatus').innerHTML = res
      })
      LogiqTokenCrowdsale.at(contract_address).ICOdeadLine.call().then(function (res) {
        if (res > 0) {
          document.getElementById('ICOdeadLine').innerHTML = timeConverter(res)
        } else {
          document.getElementById('ICOdeadLine').innerHTML = 'not defined'
        }
      })
      LogiqTokenCrowdsale.at(contract_address).weiDelivered.call().then(function (res) {
        document.getElementById('weiDelivered').innerHTML = res / ether(1)
      })
    }
  }
}

window.addEventListener('load', function () {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn('Getting network from Metamask')
    window.web3 = new Web3(web3.currentProvider)
  } else {
    console.warn('Getting localhost 127.0.0.1 network')
    window.web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:9545'))
  }

  App.start()
})
