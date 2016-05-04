public with sharing class InvestmentAccountDetailPageController {
  public InvestmentAccountWrapper invAccWrapper {get;set;}
  public Integer screenFigure {get;set;}
  public Map<Id, InvestmentWrapper> invWrapMap {get;set;}
  
  enum ErrorType {
  		
  		AUTO_INVEST_PERCENT_LIMIT, 
  		AUTO_INVEST_PERCENT_WITH_INACTIVE, ACTIVE_LIMIT, 
  		NO_ERROR, 
  		RECORD_ID_NOT_FOUND
  }
  
  static Map<ErrorType, String> errorMsgMap;
  public Boolean isErrorOnPage {get;set;}
  
  
  static{
  	errorMsgMap = new Map<ErrorType, String>{
  		ErrorType.AUTO_INVEST_PERCENT_LIMIT => Label.AUTO_INVEST_PERCENT_LIMIT,
  		ErrorType.AUTO_INVEST_PERCENT_WITH_INACTIVE => Label.AUTO_INVEST_PERCENT_WITH_INACTIVE,
  		ErrorType.ACTIVE_LIMIT => Label.ACTIVE_LIMIT,
  		ErrorType.RECORD_ID_NOT_FOUND => Label.RECORD_ID_NOT_FOUND
  	};
  }
  
  public Integer getPageSize(){
  	return SMIConstants.PAGE_SIZE;
  }
  
  public List<Investment__c> investmentList {
	  get{
	  	investmentList = new List<Investment__c>();
		for(InvestmentWrapper invWrap : invWrapMap.values()){
			investmentList.add(new Investment__c(
				Id = invWrap.investment.Id,
				Active__c = invWrap.active,
				Auto_Invest_Percent__c = invWrap.autoInvestPercent	
			));
			
		}  
		return investmentList;
	  }set;
  }
  	
  public List<Investment__c> getInvestmentChunkList(){
    	
        return (List<Investment__c>)con.getRecords();
  } 		
  
  String invAccId;
  	
	
  public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                con = new ApexPages.StandardSetController(invAccWrapper.invAcc.Investments__r);
		        con.setPageSize(2);
            }
            return con;
        }
        set;
   }
  
  public InvestmentAccountDetailPageController(ApexPages.StandardController controller) {
    
    
    screenFigure = 1;
	isErrorOnPage = false;
	invAccId = controller.getId();
    
    if(String.isNotBlank(invAccId)){
    	initData(invAccId);	
    }else{
    	isErrorOnPage = true;
    	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsgMap.get(ErrorType.RECORD_ID_NOT_FOUND)));
    }
   
    
    
  }
  
  public PageReference checkAndRedirectUser(){
  	Boolean isRedirect = false;
  	 
  	 
  	List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
	if(profiles.size() > 0){
		for(Redirect_Profile_Names__c profName : Redirect_Profile_Names__c.getall().values()){
  			if(profName.Profile_Name__c == profiles[0].Name){
  				isRedirect = true;
  			}
  		}	
	}
  	
  	
  	
  	if(isRedirect){
  		String recId = ApexPages.currentPage().getParameters().get('id');
  		if(String.isNotBlank(recId)){
	  		PageReference pageRef = new PageReference('/'+recId);
	        pageRef.getParameters().put('nooverride', '1');
	        return pageRef;
  		}
        
  	}
  	
  	return null;
  }
  
  private void initData(String recId){
  	invAccWrapper = new InvestmentAccountWrapper([SELECT id,Cash_Value__c,Name,
                                                    OwnerId,
                                                    Cash_Reserve_Percent__c,              
                                                    Active_Investments__c,
                                                    (SELECT Id,Active__c,Name,  
                                                            Auto_Invest_Percent__c,
                                                            Investment_Account__c,
                                                            Investment_Fund__c,
                                                            Price__c, Shares__c,
                                                            Trading_Symbol__c,
                                                            Value__c
                                                    
                                                    FROM Investments__r)      
                                                  FROM Investment_Account__c
                                                  WHERE Id =: recId] 
                                               );
                                               
    invWrapMap = new Map<Id, InvestmentWrapper>();
    
    for(Investment__c inv : invAccWrapper.invAcc.Investments__r){
    	invWrapMap.put(inv.Id, new InvestmentWrapper(inv));	
    }
  }
  
  public PageReference rebalanceAction(){
      screenFigure = 2;
      initData(invAccId);
      return null;
      
  }
  
  public PageReference rebalanceNowAction(){
    Transaction__c rebalanceTransaction;
       
    try{
    	
        screenFigure = 1;
        ErrorType eType = performValidations(invWrapMap.values());
        if(eType != ErrorType.NO_ERROR){
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsgMap.get(eType)));
          screenFigure = 2;  
          return null;
        }
        
        if(!investmentList.isEmpty()){
            update investmentList;
            con = null;
            
            rebalanceTransaction = new Transaction__c(
            	Transaction_Type__c = SMIConstants.REBALANCE,
            	Investment_Account__c = invAccId,
            	Transaction_Date__c = Date.today()
            	
            );
            
            insert rebalanceTransaction;
            
            
        }
                  
    }catch(DMLException ex){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
    }catch(Exception ex){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
    }
         
      return null;
      
  }
  
  public PageReference saveAction(){
      screenFigure = 1;
      
      try{
          
          System.debug('>>>>>>>>>>>> Inv Acc');
          System.debug(invAccWrapper.invAcc);
          
          update invAccWrapper.invAcc;      
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Confirm, Label.RECORD_SUCCESSFULLY_SAVED));
     
      }catch(DMLException ex){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
      }
      return null;
      
  }
  
  public PageReference cancelAction(){
      screenFigure = 1;
      
      return null;
      
  }
  
	public void next() {
		
		con.next();
	}
	
	public void previous() {
		
		con.previous();
	}
	
	public void first() {
		
		con.first();
	}
	
	public void last() {
		
		con.last();
	}
	
	
  
  private ErrorType performValidations(List<InvestmentWrapper> invList){
        ErrorType eType = ErrorType.NO_ERROR;
        Decimal totalPercent = 0;
        Integer activeCount = 0;
        
        for(InvestmentWrapper inv : invList){
            
            if(inv.active){
            	activeCount++;
            	if(inv.autoInvestPercent != null){
                	totalPercent += inv.autoInvestPercent;
            	}
            }else if(inv.autoInvestPercent != null && inv.autoInvestPercent != 0){
            	return ErrorType.AUTO_INVEST_PERCENT_WITH_INACTIVE;
            }
        } 
        
        if(totalPercent != SMIConstants.AUTO_INVEST_PERCENT_LIMIT){
        	eType = ErrorType.AUTO_INVEST_PERCENT_LIMIT;
        }else if(activeCount > SMIConstants.ACTIVE_LIMIT){
        	eType = ErrorType.ACTIVE_LIMIT;
        }
        
        return eType;
    }	
		
  
  // Wrapper class to hold values for Investment Account
  class InvestmentAccountWrapper{

    public Investment_Account__c invAcc {get;set;}
    
    public Decimal investmentValue {
      get{
        
        Decimal invVal = 0;
        
        for (Investment__c invs : invAcc.Investments__r) {
         
          invVal += invs.Value__c != null ? invs.Value__c : 0;
       
        }
        
        return invVal.setScale(2); 
      }
      set;
    }
    public Decimal totalAccountValue { 
        get{
        	Decimal totVal = investmentValue + (invAcc.Cash_Value__c != null ? invAcc.Cash_Value__c : 0);
            return totVal.setScale(2);
        }
        set;
    }
       
        
    public InvestmentAccountWrapper(Investment_Account__c invAcc){
        this.invAcc = invAcc;
       
    }
    
    
      
  }
    
  
  class InvestmentWrapper{
  	
  	public Boolean active {get;set;}
  	public Decimal autoInvestPercent {get;set;}
  	public Investment__c investment {get;set;}
  	
  	InvestmentWrapper(Investment__c investment){
  		this.investment = investment;
  		active = investment.Active__c;
  		autoInvestPercent = investment.Auto_Invest_Percent__c;
  	}
  	 
  }

  

}