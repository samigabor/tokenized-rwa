const alpacaRequest = Functions.makeHttpRequest({
  url: "https://paper-api.alpaca.markets/v2/account",
  headers: {
    accept: 'application/json',
    'APCA-API-KEY-ID': 'PKT1TUEA0ON7DWV01J2E',
    'APCA-API-SECRET-KEY': '0oDGWAKtGtt64Rd2FcEd6YcRj01Ca3hnaAuMaimY'
  }
})

const [response] = await Promise.all([alpacaRequest])
const portfolioBalance = response.data.portfolio_value
console.log(`Alpaca Portfolio Balance: $${portfolioBalance}`)
return Functions.encodeUint256(Math.round(portfolioBalance * 1000000000000000000))
