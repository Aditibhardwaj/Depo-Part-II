/**
 * Class Name - InvestmentAccountDetailController
 * Description - This class used as controller for InvestmentAccountDetailPage.
 *
 * Created Date - 14th Feb, 2016
 *
 */
public with sharing class InvestmentAccountDetailController {
  
  // This is the instance of InvestmentAccountWrapper
  public InvestmentAccountWrapper invAccWrapper {
    get;
    set;
  }
  
  // This variable represent the screen like screen1 for inline editing and screen2 for rebalance
  public Integer screenFigure {
    get;
    set;
  }
  
  public Map < Id, InvestmentWrapper > invWrapMap {
    get;
    set;
  }
  
  // This enum represents diffrent types of errors.
  enum ErrorType {
    AUTO_INVEST_PERCENT_LIMIT,
    AUTO_INVEST_PERCENT_WITH_INACTIVE, ACTIVE_LIMIT,
    NO_ERROR,
    RECORD_ID_NOT_FOUND
  }
  
  static Map < ErrorType, String > errorMsgMap;
  
  public Boolean isErrorOnPage {
    get;
    set;
  }
  
  static {
    
    errorMsgMap = new Map < ErrorType, String > {
    
      	ErrorType.AUTO_INVEST_PERCENT_LIMIT => Label.AUTO_INVEST_PERCENT_LIMIT,
        ErrorType.AUTO_INVEST_PERCENT_WITH_INACTIVE => Label.AUTO_INVEST_PERCENT_WITH_INACTIVE,
        ErrorType.ACTIVE_LIMIT => Label.ACTIVE_LIMIT,
        ErrorType.RECORD_ID_NOT_FOUND => Label.RECORD_ID_NOT_FOUND
    
    };
  }
  
  // size of page for pagination
  public Integer getPageSize() {
    return SMIConstants.PAGE_SIZE;
  }
  
  // this list will be used to update the investment data 
  private List < Investment__c > investmentList {
    get {
      transient List < Investment__c > invList = new List < Investment__c > ();
      for (InvestmentWrapper invWrap: invWrapMap.values()) {
        invList.add(new Investment__c(Id = invWrap.investment.Id, Active__c = invWrap.active,
          Auto_Invest_Percent__c = invWrap.autoInvestPercent));
      }
      return invList;
    }
    set;
  }
  
  // This is the chunk of records for a single page
  public List < Investment__c > getInvestmentChunkList() {
      return (List < Investment__c > ) con.getRecords();
	}
	
	// This variable storing the record id of Current Investment Account
	String invAccId;
  
  // This is a standard set controller, to provide pagination 	
  public ApexPages.StandardSetController con {
      get {
        if (con == null) {
          con = new ApexPages.StandardSetController(invAccWrapper.invAcc.Investments__r);
          con.setPageSize(2);
        }
        return con;
      }
      set;
    }
	
	// Constructor for controller
  public InvestmentAccountDetailController(ApexPages.StandardController controller) {
  
      screenFigure = 1;
      isErrorOnPage = false;
      invAccId = controller.getId();
  
      if (String.isNotBlank(invAccId)) {
        initData(invAccId);
      } else {
        isErrorOnPage = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsgMap.get(
          ErrorType.RECORD_ID_NOT_FOUND)));
      }
	
	}

	// @Description - This method will be invoked as action from VF page to redirect the user for 
	// 	specified profile users to standard page layout view by addin nooverride=1 in url 
	//
	// @Param       - None
	// @return      - PageReference  
	// @author      -
  public PageReference checkAndRedirectUser() {
  
      Boolean isRedirect = false;
  
      // fetching the current user profile  
      List < Profile > profiles = [ SELECT Id, Name 
      															FROM Profile 
      															WHERE Id = : userinfo.getProfileId() 
      															LIMIT 1
  																];
      if (profiles.size() > 0) {
        for (Redirect_Profile_Names__c profName: Redirect_Profile_Names__c.getall().values()) {
          if (profName.Profile_Name__c == profiles[0].Name) {
            isRedirect = true;
            break;
          }
        }
      }
  
      if (isRedirect) {
      	
        // if profile matched then redired the user
        String recId = ApexPages.currentPage().getParameters().get('id');
        if (String.isNotBlank(recId)) {
          PageReference pageRef = new PageReference('/' + recId);
          // adding nooverride in url
          pageRef.getParameters().put('nooverride', '1');
          return pageRef;
        }
      }
  
      return null;
	
	}

	// @Description - There is two use of this method once from constructor to intialize data 
	// 	and again when need to discard the changes 
	// @Param       - String recId, this is the id of record(Investment Account) 
	// @return      - Void - it just populate the records  
	// @author      -
  private void initData(String recId) {
  
      // populate InvestmenAccountWrapper by querying the data from database
      invAccWrapper = new InvestmentAccountWrapper(
	      	[SELECT id, Cash_Value__c, Name,
	        OwnerId,
	        Cash_Reserve_Percent__c,
	        Active_Investments__c, 
	        	( SELECT Id, Active__c, Name, Auto_Invest_Percent__c,
	          	Investment_Account__c, Investment_Fund__c, Price__c, Shares__c, Trading_Symbol__c,
	          	Value__c 
	          	FROM Investments__r
	      		)
	        
	        FROM Investment_Account__c
	        WHERE Id = : recId
      	]
  		);
  		
      invWrapMap = new Map < Id, InvestmentWrapper > ();
      
      // Populating invWrapMap, this map will hold update from user
      for (Investment__c inv: invAccWrapper.invAcc.Investments__r) {
        invWrapMap.put(inv.Id, new InvestmentWrapper(inv));
      }
	}
	
	// This is method is used to redirect to screen2 and discard the data on screen1 
  public PageReference rebalanceAction() {
      screenFigure = 2;
      initData(invAccId);
      return null;
	}
	// This method perform the rebalancing, here we are performing 3 steps
	// 1. validate investments
	// 2. save investments
	// 3. create a rebalnce transaction
  public PageReference rebalanceNowAction() {
  
      Transaction__c rebalanceTransaction;
  
      // adding transaction to revert the investment update in case rebalance transaction fails
      Savepoint sp = Database.setSavepoint();
  
      try {
  
        screenFigure = 1;
        ErrorType eType = performValidations(invWrapMap.values());
        if (eType != ErrorType.NO_ERROR) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsgMap.get(
            eType)));
          screenFigure = 2;
          return null;
        }
  
        if (!investmentList.isEmpty()) {
          update investmentList;
          con = null;
          rebalanceTransaction = new Transaction__c(
          	Transaction_Type__c = SMIConstants.REBALANCE,
            Investment_Account__c = invAccId, 
            Transaction_Date__c = Date.today()
        	);
          
          insert rebalanceTransaction;
        }
  
      } catch (DMLException ex) {
        Database.rollback(sp);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
  
      } catch (Exception ex) {
        Database.rollback(sp);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
      }
  
      return null;
	}
	
	// In this method we are saving the Investment Account records, 
	// purpose is to just update Case Value
  public PageReference saveAction() {
      screenFigure = 1;
      Savepoint sp = Database.setSavepoint();
      
      try {
      
        update invAccWrapper.invAcc;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm, Label.RECORD_SUCCESSFULLY_SAVED));
      
      } catch (DMLException ex) {
        Database.rollback(sp);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
      }
      
      return null;
	}
	
	// This is redirect to screen1
  public PageReference cancelAction() {
      screenFigure = 1;
      return null;
	}
	
	// it moves the page to next for standard set controller 
  public void next() {
      con.next();
	}
	
	// it moves to the previous page for standard set controller
  public void previous() {
      con.previous();
	}
	
	// it moves to first page for standard set controller
  public void first() {
      con.first();
	}
	
	// it moves to last page for standard set controller
  public void last() {
      con.last();
	}
	
	// @Description - Retrieving selected stations list for edit screen hover 
	// @Param       - List<InvestmentWrapper> invList - list of investment to be validate
	// @return      - ErrorType - type of error enum 
	// @author      - 
  private ErrorType performValidations(List < InvestmentWrapper > invList) {
      ErrorType eType = ErrorType.NO_ERROR;
      Decimal totalPercent = 0;
      Integer activeCount = 0;
  
      for (InvestmentWrapper inv: invList) {
        if (inv.active) {
          activeCount++;
          if (inv.autoInvestPercent != null) {
            totalPercent += inv.autoInvestPercent;
          }
        } else if (inv.autoInvestPercent != null && inv.autoInvestPercent != 0) {
          return ErrorType.AUTO_INVEST_PERCENT_WITH_INACTIVE;
        }
      }
  
      if (totalPercent != SMIConstants.AUTO_INVEST_PERCENT_LIMIT) {
        eType = ErrorType.AUTO_INVEST_PERCENT_LIMIT;
      } else if (activeCount > SMIConstants.ACTIVE_LIMIT) {
        eType = ErrorType.ACTIVE_LIMIT;
      }
  
      return eType;
    }
	
	// Wrapper class to hold values for Investment Account
  class InvestmentAccountWrapper {
    public Investment_Account__c invAcc {
      get;
      set;
    }
  
    // It returns investment value, which is some of Values of investments
    public Decimal investmentValue {
      get {
        Decimal invVal = 0;
        for (Investment__c invs: invAcc.Investments__r) {
          invVal += invs.Value__c != null ? invs.Value__c : 0;
        }
        return invVal.setScale(2);
      }
    }
  
    // It returns totalAccountValue, which is some of Investment value 
    // and Cash value of Investment Account
    public Decimal totalAccountValue {
      get {
        Decimal totVal = investmentValue + (invAcc.Cash_Value__c != null ? invAcc.Cash_Value__c : 0);
        return totVal.setScale(2);
      }
    }
  
    // constructor       
    public InvestmentAccountWrapper(Investment_Account__c invAcc) {
      this.invAcc = invAcc;
    }
  
  }
  
  // This is a wrapper class to hold Investment and editable fields of investment 
  // so that we can avoid Modified rows exist in the records collection! error 
  // while using standard set controller 
  class InvestmentWrapper {
    public Boolean active {
      get;
      set;
    }
    public Decimal autoInvestPercent {
      get;
      set;
    }
    public Investment__c investment {
      get;
      set;
    }
    // constructor
    public InvestmentWrapper(Investment__c investment) {
      this.investment = investment;
      active = investment.Active__c;
      autoInvestPercent = investment.Auto_Invest_Percent__c;
    }
  }
}