trigger InvoiceTrigger on Invoice (after insert, after update) {
    
    InvoiceTriggerHandler handler = new InvoiceTriggerHandler();
    if(trigger.isBefore){
       if(trigger.isInsert){
        
        } 
        if(trigger.isUpdate){
        
        } 
    }
    if(trigger.isAfter){
       if(trigger.isInsert){
        
        } 
        if(trigger.isUpdate){
            handler.onAfterUpdate(Trigger.New, Trigger.Old, Trigger.NewMap, Trigger.OldMap);
        } 
    }
}