/********************************************************************************************
* Class Name: TransactionsTriggerHelper
* Author: candidate@653818advdev.com 
* Date: [2/13/2016]
* Requirement Description: This is helper class for TrasactionTriggerHandler.
* Date Modified                Modified By                  Description of the update

***********************************************************************************************/
public class TransactionsTriggerHelper{
   
	// This Method parent Investment for transaction.
	public Map<Id,Investment__c> getInvestmentMap(List<Transaction__c> transactionList){
		
		// Set contains investment account Id 
		// for transaction
		Set<Id> invIdSet = new Set<Id>();
    
    // Map will hold Parent Invesments of trasaction.
		Map<Id,Investment__c> investmentMap = new Map<Id,Investment__c>();

		// Populate invIdSet 
		for(Transaction__c trans : transactionList){
				invIdSet.add(trans.Investment__c);
		}

		// Get all parent Investment accounts and
		// Investments for transactions in list
		investmentMap = new Map<id,Investment__c>( [SELECT Id,Active__c,
																											Auto_Invest_Percent__c,
																											Investment_Account__c,
																											Investment_Fund__c,
																											Price__c,	Shares__c,
																											Trading_Symbol__c,
																											Value__c,
																											Investment_Account__r.Cash_Value__c,
																											Investment_Account__r.Cash_Reserve_Percent__c,							
																											Investment_Account__r.Active_Investments__c
																								FROM Investment__c
																								WHERE Id In :invIdSet ]);
												
		
		// return parent investment to update																										
		return investmentMap;																															
	}	

	// This Method get parent investment account 
	// and parent Investment for transaction.
	public Map<Id,Investment_Account__c> getInvestmentAccountMap(List<Transaction__c> transactionList){
		
		// Set contains investment account Id 
		// for transaction
		Set<Id> accountIdSet = new Set<Id>();

		// Populate accountIdSet 
		for(Transaction__c trans : transactionList){
				accountIdSet.add(trans.Investment_Account__c);
		}

		// Get all parent investment accounts and
		// Investments for transactions in list
		Map<Id, Investment_Account__c> investmentAccMap = new Map<id,Investment_Account__c>( 
																														[SELECT id,Cash_Value__c,
																																	Cash_Reserve_Percent__c,							
																																	Active_Investments__c,
																															(SELECT		
																																	Id,Active__c,
																																	Auto_Invest_Percent__c,
																																	Investment_Account__c,
																																	Investment_Fund__c,
																																	Price__c,	Shares__c,
																																	Trading_Symbol__c,
																																	Value__c
																																	
																																FROM Investments__r)			
																														FROM Investment_Account__c
																														WHERE Id In :accountIdSet ]);
												
		
		// Return parent investment to update 																										
		return investmentAccMap;																															
	}

	

	// Method will update Parent Investment 
	// and Investment Account when type of transaction 
	public void updateParentInvestmentAndAccount(List<Transaction__c> transactionList){

		// Instance of investment
		Investment__c inv;
		// Instance of investment Account
		Investment_Account__c invAcc;
		// Map will contain parent investment of transaction inserted
		Map<Id,Investment__c> investmentMap = getInvestmentMap(transactionList);
		// Map will contain parent investment account of transaction inserted
		Map<Id, Investment_Account__c> investmentAccMap = getInvestmentAccountMap(transactionList);
    
    // Check If Invesment Account Exist Or Not
    if( investmentAccMap != null ){

			// Iterate all transaction 
			for(Transaction__c trans : transactionList){
				
				inv = null;
				if( investmentAccMap.containsKey(trans.Investment_Account__c )) {
				
					// Investment Account
					invAcc = investmentAccMap.get(trans.Investment_Account__c);						
					
					// If Investment exist for transaction
					if( investmentMap != null 
							&& investmentMap.containsKey(trans.Investment__c)){
						inv = investmentMap.get(trans.Investment__c);	
					}
			
					if(trans.Transaction_Type__c == SMIConstants.DEPOSIT){
						
						// Add cash value of transaction to Cash value of
						// investment account when transaction type is DEPOSIT
						invAcc.Cash_Value__c 
										= (invAcc.Cash_Value__c != null ? invAcc.Cash_Value__c : 0)
												+ trans.Cash__c;
						
						} else if(trans.Transaction_Type__c == SMIConstants.WITHDRAW){
								
								// Check If Account has sufficient cash to withdraw
								if(trans.Cash__c > invAcc.Cash_Value__c ){

										trans.addError(Label.INSUFFICIENT_CASH);	
								} else {
							
									// Subtract cash value of transaction from Cash value of
									// investment account when transaction type is withdraw
									invAcc.Cash_Value__c 
													= (invAcc.Cash_Value__c != null ?
														 invAcc.Cash_Value__c : 0) - trans.Cash__c;
								}
											

						} else if( trans.Transaction_Type__c == SMIConstants.BUY
												&& inv != null ) {

								if(inv.Price__c * trans.Shares__c > invAcc.Cash_Value__c ){
										trans.addError(Label.INSUFFICIENT_CASH_TO_BUY);
											
								} else {
									// Increase number of share on investment 
									// if transaction is of type BUY
									inv.Shares__c = (inv.Shares__c != null ? 
																		inv.Shares__c : 0) + trans.Shares__c;
									
									// Decrease cash value from investment account
									// if transaction is of type BUY
									invAcc.Cash_Value__c 
													= (invAcc.Cash_Value__c != null ?
														 	invAcc.Cash_Value__c : 0) - inv.Price__c * trans.Shares__c;

								}		 			
						} else if( trans.Transaction_Type__c == SMIConstants.SELL
												&& inv != null ) {
								
								// Check If investment has sufficient share to sell
								if( trans.Shares__c > inv.Shares__c ){
										trans.addError(Label.INSUFFICIENT_SHARE);	
								} else {
									
									// Decrease number of shares from investment 
									// if transaction is of type SELL
									inv.Shares__c = (inv.Shares__c != null ?
																	 inv.Shares__c : 0) - trans.Shares__c;
									
									// Increase cash value on account 
								 	// if transaction is of type SELL
									invAcc.Cash_Value__c = (invAcc.Cash_Value__c != null ?
																						invAcc.Cash_Value__c : 0) + 
														 								inv.Price__c * trans.Shares__c;
								}	

					}
				}
			} 
		}

		// Update parent Investments
		if(!investmentMap.isEmpty()){
				Database.SaveResult[] investmentResults 
															= Database.Update(investmentMap.values(), true);
			for (integer i = 0; i < investmentResults.size(); i++) {
         Database.SaveResult result = investmentResults[i];
         if (!result.isSuccess() && result.getErrors().size() > 0) {
           investmentMap.values()[i].addError(result.getErrors()[0].getMessage());
           
         } 
       }  
		}

		// Update parent Investment Accounts
		if(!investmentAccMap.isEmpty()){
				Database.SaveResult[] investmentAccResults 
															= Database.Update(investmentAccMap.values(), true);
			
			for (integer i = 0; i < investmentAccResults.size(); i++) {
         Database.SaveResult result = investmentAccResults[i];
         if (!result.isSuccess() && result.getErrors().size() > 0) {
           investmentAccMap.values()[i].addError(result.getErrors()[0].getMessage());
           
         } 
       }  												
		}	
	}

	// This Method performs rebalance operation on Investment account
	public void rebalanceInvestmentAccount (List<Transaction__c> transactionList) {
		
		// Map will hold rebalancing amount for investment account
		Map<id, Decimal> rebalanceAmountMap = new Map<id, Decimal>();
		// List will hold transaction record to insert
		List<Transaction__c> transList = new List<Transaction__c>();

		Investment__c inv;
		Investment_Account__c invAcc;

		Decimal totalAccountValue = 0.0;
		Decimal targetCashValue = 0.0;
		Decimal numberOfInvestments = 0;
		Decimal rebalanceAmount = 0.0;
		Decimal numberOfShares = 0;

		// Get Investment Account
		Map<Id, Investment_Account__c> investmentAccMap 
																	= getInvestmentAccountMap(transactionList);														

		// Calculate total Investment value 
		for(Id invAccId : investmentAccMap.keySet()){
			totalAccountValue = 0;

			for(Investment__c invs : investmentAccMap.get(invAccId).Investments__r ){
				totalAccountValue += invs.Value__c != null ? invs.Value__c : 0;
			}

			totalAccountValue += investmentAccMap.get(invAccId).Cash_Value__c != null ? 
														investmentAccMap.get(invAccId).Cash_Value__c : 0;

			targetCashValue = investmentAccMap.get(invAccId).Cash_Reserve_Percent__c
												 * totalAccountValue / 100 ;											
														
			
			// Put investment account id and rebalance amount 
			rebalanceAmountMap.put(invAccId, totalAccountValue - targetCashValue);

		}
	
		// Calculate number of shares on investment 
		// and create BUY or SELL transaction based
		// on number of shares. 
		for(Id invAccId : investmentAccMap.keySet()){
			for(Investment__c invs : investmentAccMap.get(invAccId).Investments__r ){
				
				if(invs.Active__c){

					// Calculate number of share for investment
					numberOfShares = (rebalanceAmountMap.get(invAccId) / 100 * 
															invs.Auto_Invest_Percent__c) / invs.Price__c;

					// Check to create transaction of type BUY OR SELL
					if(numberOfShares != invs.Shares__c){
						// Calculated number of shares are 
						// more than number of share on investment
						if(numberOfShares > invs.Shares__c){
							// Create BUY transaction
							transList.add(createTransaction(SMIConstants.BUY, invAccId, invs.Id, 
																								numberOfShares - invs.Shares__c));	
						}else{
							// Calculated number of shares are 
							// less than number of share on investment
							// Create SELL transaction
							transList.add(createTransaction(SMIConstants.SELL, invAccId, 
																							invs.Id, invs.Shares__c - numberOfShares));	
						}
					}	

					
				}else{
					
					// If Investment is not active then
					// Create SELL transaction for all 
					// shares on investment 
					transList.add(createTransaction(SMIConstants.SELL, invAccId, 
																						invs.Id, invs.Shares__c));	
				}

			}
		}

		// Insert transaction
		if(!transList.isEmpty()){
			insert transList;
		}

	}

	// Method will return transaction record to insert
	private Transaction__c createTransaction(String type, String invAccId, 
																							String invId, Decimal shares){
		return new Transaction__c(
					Transaction_Type__c = type,
					Investment_Account__c = invAccId,
					Investment__c = invId,
					Shares__c = shares,
					Transaction_Date__c = system.today()
			);
	}

	

}