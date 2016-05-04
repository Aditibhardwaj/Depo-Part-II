/********************************************************************************************
* Class Name: TransactionsTriggerHandler
* Author:
* Date: [2/13/2016]
* Requirement Description: This is helper class for TrasactionTrigger.
* Date Modified                Modified By                  Description of the update

***********************************************************************************************/
public class TransactionsTriggerHandler{

	// This method will be invoked by Transaction Trigger for 
	// each after insert event.
	public Static void onAfterInsert(List<Transaction__c> transactionList){
		
		// Instance of helper class
		TransactionsTriggerHelper helper = new TransactionsTriggerHelper();
		
		List<Transaction__c> rebalanceTransList = new List<Transaction__c>();
		List<Transaction__c> nonRebalanceTransList = new List<Transaction__c>();

		
		for(Transaction__c trans : transactionList){
			if(trans.Transaction_Type__c == SMIConstants.REBALANCE){
				rebalanceTransList.add(trans);
			}else if(trans.Transaction_Type__c == SMIConstants.BUY
				|| trans.Transaction_Type__c == SMIConstants.SELL
				|| trans.Transaction_Type__c == SMIConstants.WITHDRAW
				|| trans.Transaction_Type__c == SMIConstants.DEPOSIT){
				nonRebalanceTransList.add(trans);
			}
		}

		if(!nonRebalanceTransList.isEmpty()){
			helper.updateParentInvestmentAndAccount(nonRebalanceTransList);
		}

		if(!rebalanceTransList.isEmpty()){
			helper.rebalanceInvestmentAccount(rebalanceTransList);
		}

	}
	
}