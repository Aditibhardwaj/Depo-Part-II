/**
* Class Name: TransactionTriggerHelperTest
* Author: 
* Date: [2/25/2016]
* Requirement Description: Test class for TransactionTriggerHelper
* Date Modified                Modified By                  Description of the update
*
**/
@isTest
private class TransactionTriggerHelperTest{
	
	static Profile prof;
	static User usr;
	static Investment_Account__c invAcc;
	static List<Investment_Fund__c> invFundList 
									= new List<Investment_Fund__c >();
	static List<Investment__c> invList 
									= new List<Investment__c >();

	static{
	prof = [SELECT Id FROM Profile WHERE Name='SMI Investor'];
	usr = new User(Alias = 'newUser', Email='newuser@testorg.com',
         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
         LocaleSidKey='en_US', ProfileId = prof.Id,
         TimeZoneSidKey='America/Los_Angeles', UserName='invsetor@testorg.com');
	}

	// Method to create test data
	private static void createTestData(){
		
		invAcc = TestUtility.createInvestmentAccount('Test Inv Acc',900000000.0,10.0,true);
		invFundList = TestUtility.createInvestmentFunds(100,true);
		invList = TestUtility.createInvestments(100, invAcc, invFundList,true);
	}

	// Method to test deposit transaction on investment account
	static testMethod void createDepositTransactionTest() {
		List<Transaction__c> transList = new List<Transaction__c >();
		createTestData();
		Investment_Account__c acc = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];

		system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(100,invAcc,invList,
																								SMIConstants.DEPOSIT,500,0,true);
			Test.stopTest();
		}																			
																						 
		Investment_Account__c acc1 = [SELECT id,Cash_Value__C 
																	FROM Investment_Account__c  
																	WHERE id = :invAcc.id];																			 
		System.assertNotEquals(Acc.Cash_Value__C ,acc1.Cash_Value__C)	;	
		System.assertEquals(acc1.Cash_Value__C,acc.Cash_Value__C+ 500 *100);																		 

	}
 	
 	// Method to test withdraw transaction on investment account
 	static testMethod void createWithdrawTransactionTest() {
		List<Transaction__c> transList = new List<Transaction__c >();
		createTestData();
		Investment_Account__c acc = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];

		system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(100,invAcc,invList,
																								SMIConstants.WITHDRAW,5,0,true);
			Test.stopTest();
		}																			
																						 
		Investment_Account__c acc1 = [SELECT id,Cash_Value__C 
																	FROM Investment_Account__c  
																	WHERE id = :invAcc.id];																			 
		System.assertNotEquals(Acc.Cash_Value__C ,acc1.Cash_Value__C)	;	
		System.assertEquals(acc1.Cash_Value__C,acc.Cash_Value__C - 5*100);	
	}

 	// Method to test if withdraw amount is more than 
 	// cash on investment account
 	static testMethod void createWithdrawTransactionExceptionTest() {
		
		List<Transaction__c> transList = new List<Transaction__c >();
		createTestData();
		Investment_Account__c acc = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];
		try{														
		system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(100,invAcc,invList,
																								SMIConstants.WITHDRAW,110000000,0,true);
			Test.stopTest();
		}		
		} catch(Exception ex){
			System.debug('Exception encountered while attempting to insert log records: ' + ex.getMessage());
		}																	
																						 
		Investment_Account__c acc1 = [SELECT id,Cash_Value__C 
																	FROM Investment_Account__c  
																	WHERE id = :invAcc.id];																			 
		System.assertEquals(acc.Cash_Value__C ,acc1.Cash_Value__C);	
		
	}

	
	// Method to test Buy transaction on investment account
	static testMethod void createBuyTransactionTest() {
		List<Transaction__c> transList = new List<Transaction__c >();
		createTestData();
		
		
		Investment_Account__c acc = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];
		Investment__c inv = [SELECT id,Shares__c From Investment__c
												 WHERE Id = :invlist[0].id];
		system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(100,invAcc,invlist,
																									SMIConstants.BUY,0,5,true);
			Test.stopTest();
		}																			
																						 
		Investment__c inv1 = [SELECT id,Shares__c From Investment__c
												 	WHERE Id = :invlist[0].id];		
		Investment_Account__c acc1 = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];										 																	 
		
		System.assertNotEquals(acc.Cash_Value__C ,acc1.Cash_Value__C)	;	
		System.assert(acc1.Cash_Value__C < acc.Cash_Value__C );	
		
		System.assertNotEquals(inv.Shares__c ,inv1.Shares__c)	;	
		System.assert(inv1.Shares__c > inv.Shares__c );	

	}

	// Method to test if buying amount is more than
	// cash on investment account
	static testMethod void createBuyTransactionExceptionTest() {
		List<Transaction__c> transList = new List<Transaction__c >();
		createTestData();
		
		
		Investment_Account__c acc = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];
		Investment__c inv = [SELECT id,Shares__c From Investment__c
												 WHERE Id = :invlist[0].id];
		try{
			system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(100,invAcc,invlist,
																									SMIConstants.BUY,0,50000000,true);
			Test.stopTest();
			}	
		}catch(Exception ex){
			System.debug('Exception encountered while attempting to insert log records: ' + ex.getMessage());
		}																			
																						 
		Investment__c inv1 = [SELECT id,Shares__c From Investment__c
												 	WHERE Id = :invlist[0].id];		
		Investment_Account__c acc1 = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];										 																	 
		
		System.assertEquals(acc.Cash_Value__C ,acc1.Cash_Value__C)	;	
		System.assertEquals(inv.Shares__c ,inv1.Shares__c)	;	
			

	}

	// Method to test if number of share to sell in transaction 
	// are more than number of shares on investment.
	static testMethod void createSellTransactionExceptionTest() {
		
		List<Transaction__c> transList = new List<Transaction__c >();
		createTestData();
			
		Investment_Account__c acc = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];
		Investment__c inv = [SELECT id,Shares__c From Investment__c
												 WHERE Id = :invlist[0].id];
		try{
			system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(100,invAcc,invlist,
																									SMIConstants.SELL,0,5000000,true);
			Test.stopTest();
			}	
		}catch(Exception ex){
			System.debug('Exception encountered while attempting to insert log records: ' + ex.getMessage());
		}																				
																						 
		Investment__c inv1 = [SELECT id,Shares__c From Investment__c
												 	WHERE Id = :invlist[0].id];		
		
		Investment_Account__c acc1 = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];										 																	 
		
		System.assertEquals(acc.Cash_Value__C ,acc1.Cash_Value__C)	;	
		System.assertEquals(inv.Shares__c ,inv1.Shares__c)	;	
		
	
	}

	// Method to test sale transaction on investment account
	static testMethod void createSellTransactionTest() {
		
		List<Transaction__c> transList = new List<Transaction__c >();
		createTestData();
			
		Investment_Account__c acc = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];
		Investment__c inv = [SELECT id,Shares__c From Investment__c
												 WHERE Id = :invlist[0].id];
		
		system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(100,invAcc,invlist,
																									SMIConstants.SELL,0,5,true);
			Test.stopTest();
			}	
																				
																						 
		Investment__c inv1 = [SELECT id,Shares__c From Investment__c
												 	WHERE Id = :invlist[0].id];		
		
		Investment_Account__c acc1 = [SELECT id,Cash_Value__C 
																FROM Investment_Account__c  
																WHERE id = :invAcc.id];										 																	 
		
		System.assertNotEquals(acc.Cash_Value__C ,acc1.Cash_Value__C)	;
		System.assert(acc1.Cash_Value__C > acc.Cash_Value__C );		
		System.assertNotEquals(inv.Shares__c ,inv1.Shares__c)	;	
		System.assert(inv1.Shares__c < inv.Shares__c );	
		
	
	}

	// Method to test rebalance transaction on investment account
	static testMethod void createRebalanceTransactionTest() {
		List<Transaction__c> transList = new List<Transaction__c >();
		List<Transaction__c> transListAfterRebalance = new List<Transaction__c >();
		Investment_Account__c invAccount;
		List<Investment__c> investmentList = new List<Investment__c>();
		List<Investment_Fund__c> investmentFundList = new List<Investment_Fund__c>();
		
		invAccount = TestUtility.createInvestmentAccount('Test Inv Acc',10000,10.0,true);
		investmentFundList = TestUtility.createInvestmentFunds(100,true);
		investmentList = TestUtility.createInvestments(7, invAccount, investmentFundList,true);

		system.runAS(usr) {
			Test.startTest();
			transList = TestUtility.createTransactions(5,invAccount,investmentList,
																								SMIConstants.REBALANCE,0,0,true);
			Test.stopTest();
		}																			
																						 
		transListAfterRebalance = [SELECT Id FROM Transaction__c 
															WHERE Investment_Account__c = : invAccount.id];																 
		System.assertNotEquals(transListAfterRebalance.size() ,transList.size())	;	
		System.assert(transListAfterRebalance.size() > transList.size() );
	} 


	// Method to test if cash on investment account finished during rebalancing
	public static testMethod void createRebalanceTransactionExceptionTest() {
		List<Transaction__c> transList = new List<Transaction__c >();
		List<Transaction__c> transListAfterRebalance = new List<Transaction__c >();
		createTestData();
		
		system.runAS(usr) {
		try{
			Test.startTest();
			
			transList = TestUtility.createTransactions(500,invAcc,invList,
																								SMIConstants.REBALANCE,0,0,true);
			Test.stopTest();
		} catch(Exception ex){
			System.debug('Exception encountered while attempting to insert log records: ' + ex.getMessage());
		}
		
		}																			
																						 
		transListAfterRebalance = [SELECT Id FROM Transaction__c 
															WHERE Investment_Account__c = : invAcc.id];																 
		System.assertEquals(transListAfterRebalance.size() ,transList.size())	;	
		
	}

}