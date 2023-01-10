/*
***********************************************************************
    Name        : AddressTrigger
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 01, 2022
    Description : Trigger to automate logic running on Address object during multiples events
***********************************************************************
*/

trigger AddressTrigger on Address (before insert, before update, after update) {
    
    AddressTriggerHandler handler = new AddressTriggerHandler();
    
    if(trigger.isBefore){
        //Insert
        if(trigger.isInsert){
            //handler.onBeforeInsert(Trigger.New, Trigger.newMap);
        }
        //Update
        if(trigger.isUpdate){
            handler.onBeforeUpdate(Trigger.New, Trigger.Old, Trigger.newMap, Trigger.oldMap);
        }
    }
    if(trigger.isAfter){
        //Insert
        if(trigger.isInsert){
            //handler.onAfterInsert(Trigger.New, Trigger.newMap);
        }
        //Update
        if(trigger.isUpdate){
            handler.onAfterUpdate(Trigger.New, Trigger.old, trigger.newMap, Trigger.oldMap);
        }
    }
}