const {Defender} = require('@openzeppelin/defender-sdk');
const {ethers} = require('ethers');

exports.handler = async function(credentials) {
    const STRATEGY_ABI = [
        "function isPaused() external view returns (bool)",
        "function rebalanceAndReport() external returns (uint256,uint256,uint256)",
    ]
    const strategy = "0x341A2c85C499895331fa2977EB1908939676cE83"
    const client = new Defender(credentials);

    const provider = client.relaySigner.getProvider();
    const signer = await client.relaySigner.getSigner(provider);
    const strategyContract = new ethers.Contract(strategy, STRATEGY_ABI, signer);

    try {
        const isPaused = await strategyContract.isPaused();
        if (isPaused) {
            console.log("Strategy is paused, skip");
            return {status : "skipped", reason : "strategy_paused"};
        }
        await strategyContract.rebalanceAndReport();
        return {status : "success", reason : "strategy will be rebalanced and reported"};
    } catch(e){
        console.log("error rebalanceAndReport contract:", e);
        return {status : "error", reason : "strategy error"};
    }
}
