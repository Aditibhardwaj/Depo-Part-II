/********************************************************************************************
* Trigger Name: TransactionTrigger 
* Author: Aditi Bhardwaj 
* Date: [2/13/2016]
* Requirement Description: Transaction Trigger for all CRUD events.
* summary : There are 7 trigger events. 3 BEFORE Events (Insert, Update, Delete), 4 AFTER Events (Insert, Update, Delete, Undelete).
*            Best Practice for trigger development in SF dictates there should be only one trigger class created for each sObject. Using 
*            this template provides single source for all sObject trigger events as well as control over the execution order. 
*
* Date Modified                Modified By                  Description of the update

***********************************************************************************************/
trigger TransactionTrigger on Transaction__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	if(trigger.isAfter && trigger.isInsert){
		TransactionsTriggerHandler.onAfterInsert(trigger.new);
	}

}