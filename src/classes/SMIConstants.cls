/********************************************************************************************
* Class Name: SMIConstants 
* Author:  
* Date: [2/13/2016]
* Requirement Description: Class containing constant values used for SMI project.
* Date Modified                Modified By                  Description of the update

***********************************************************************************************/
public class SMIConstants {
  
  // This constant used on InvestmentAccountDetailPageController to 
  // define page size for pagination
  public static final Integer PAGE_SIZE = 2;
  
  public static final Integer AUTO_INVEST_PERCENT_LIMIT = 100;
  public static final Integer ACTIVE_LIMIT = 100; 
  
  public static final String BUY = 'BUY';
  public static final String DEPOSIT = 'DEPOSIT';
  public static final String REBALANCE = 'REBALANCE';
  public static final String SELL = 'SELL';
  public static final String WITHDRAW = 'WITHDRAW';
  public static final Set<String> TRANSACTION_TYPE =
  																			 new Set<String> {'BUY','DEPOSIT','SELL',
																			 										'REBALANCE','WITHDRAW'};	
																																			
																																					
}