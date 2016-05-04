/**
 * Class Name - TestUtility
 * Description - It provides some utility methods for test classes, to avoid repetitive code
 *
 * Created Date - 22nd Feb, 2016
 *
 */

public class TestUtility{

	// This method create multiple investment fund records
	public static List<Investment_Fund__c> createInvestmentFunds(Integer numberOfInvestment, 
																																Boolean isInsert) {
																														
		List<Investment_Fund__c> invFundList = new List<Investment_Fund__c>();
		Investment_Fund__c invFund;
		for(Integer i=0;i<numberOfInvestment;i++){
			invFund = createInvestmentFund(
				'Test Fund'+ i,
				'T'+i,
				10 + i * 5,
				false
			);
				
			invFundList.add(invFund);
		}	
		
		if(isInsert){
			insert invFundList;
		}
		
		return invFundList;

	}
	
	// This method create single investment fund records
	public static Investment_Fund__c createInvestmentFund(
		String name,
		String tSymbol,
		Decimal price,
		Boolean isInsert) {
																											
		Investment_Fund__c invFund;
		
		invFund = new Investment_Fund__c();
		invFund.Name = name;
		invFund.Trading_Symbol__c = tSymbol;
		invFund.Price__c = price;
				
		if(isInsert){
			insert invFund;
		}
		
		return invFund;

	}
	
	// This method create multiple investment accounts
	public static List<Investment_Account__c> createInvestmentAccounts(Integer numberOfInvAcc, Boolean isInsert){
																																		

		List<Investment_Account__c> invAccList = new List<Investment_Account__c>();
		Investment_Account__c invAcc;
		for(Integer i = 0; i<numberOfInvAcc; i++){
			
			invAcc = createInvestmentAccount(
				'Test Investment Account' + i,
				10.0 + 10.0 * i,
				.10 * i,
				false
			);
			
			invAccList.add(invAcc);
		}
		
		if(isInsert){
			insert invAccList;
		}
		
		return invAccList;
	}
	
	// This method create single investment account record
	public static Investment_Account__c createInvestmentAccount(
		String name,
		Decimal cashValue,
		Decimal cashResPercent, 
		Boolean isInsert){
		
		Investment_Account__c invAcc = new Investment_Account__c();
		invAcc.Name = 'Testing Inv Acc';
		invAcc.Cash_Value__c = cashValue;
		invAcc.Cash_Reserve_Percent__c = cashResPercent;
						
		if(isInsert){
			insert invAcc;
		}
		
		return invAcc;
	}
	
	// It creates multple investment records
	public static List<Investment__c> createInvestments(Integer numberOfInvestment,
																						Investment_Account__c invAcc,
																						List<Investment_Fund__c> invFundList,
																						Boolean isInsert){

		List<Investment__c> invList = new List<Investment__c>();
		Investment__c inv;
		for(Integer i=0;i<numberOfInvestment;i++){
			inv = createInvestment(
				'Test Investment' + i,
				invAcc.id,
				invFundList[i].id,
				500 +i*10,
				1 + i,
				true,
				false
			);
			
			invList.add(inv);

		} 
		if(isInsert){
			insert invList;
		}
		
		return invList;
	}
	
	// It creates single investment record
	public static Investment__c createInvestment(
		String name,
		Id invAccId,
		Id fundId,
		Decimal shares,
		Decimal autoInvPercent,
		Boolean active,
		Boolean isInsert){
		
			
		Investment__c inv = new Investment__c();
		inv.Name = name;
		inv.Investment_Account__c = invAccId;
		inv.Investment_Fund__c = fundId;
		inv.Shares__c = shares;
		inv.Auto_Invest_Percent__c = autoInvPercent;
		inv.Active__c = active;
						
		if(isInsert){
			insert inv;
		}
		
		return inv;
	}

	// It created multiple transaction records
	public static List<Transaction__c> createTransactions(Integer numberOfTransaction,
																											Investment_Account__c invAcc,
																											List<Investment__c> invList	,
																											String type,Decimal cash,
																											Integer numberOfShare,
																											Boolean isInsert){
																										
		List<Transaction__c> transactionList = new List<Transaction__c>();
		Transaction__c trans;
		for(Integer i = 0 ;i < numberOfTransaction; i++){
			trans = createTransaction(
				invAcc.id,
				invList[i].id,
				system.today(),
				type,
				cash,
				numberOfShare,
				false
			);
			
			transactionList.add(trans);
		}
		
		
		if(isInsert){
			insert transactionList;
		}
		
		return transactionList;
	}
	
	// It creates single transaction record
	public static Transaction__c createTransaction(
		Id invAccId,
		Id invId,
		Date transactionDate,
		String type,
		Decimal cash,
		Integer numberOfShare,
		Boolean isInsert){
																										
		
		Transaction__c trans = new Transaction__c();
		trans.Investment_Account__c = invAccid;
		trans.Transaction_Date__c = transactionDate;
		trans.Transaction_Type__c = type;
		if(type == SMIConstants.DEPOSIT || type == SMIConstants.WITHDRAW){
			trans.Cash__c = cash;
		} else if (type == SMIConstants.SELL || type == SMIConstants.BUY ){
			trans.Investment__c = invId;
			trans.Shares__c = numberOfShare;
		} 
			
		
		if(isInsert){
			insert trans;
		}
		
		return trans;
	}
	
	
	
}