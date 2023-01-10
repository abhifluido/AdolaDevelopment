/*
    ***********************************************************************
    Name        : AddressTriggerHandler
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 01, 2022
    Description : Handler class for AddressTrigger to call various helper class methods
    ***********************************************************************
*/
public class AddressTriggerHandler {
    //Helper initialization
    AddressTriggerHelper helper = new AddressTriggerHelper();
    public void onBeforeInsert(list<Schema.Address> newAddressList, Map<id,Schema.Address> newAddressMap){
        
    }
    public void onBeforeUpdate(list<Schema.Address> newAddressList, list<Schema.Address> oldAddressList,Map<id,Schema.Address> newAddressMap,Map<id,Schema.Address> oldAddressMap){
        //helper.updateLocationOnAddress(newAddressList,oldAddressMap);
    }
    public void onAfterInsert(list<Schema.Address> newAddressList,Map<id,Schema.Address> newAddressMap){
        
    }
    public void onAfterUpdate(list<Schema.Address> newAddressList, list<Schema.Address> oldAddressList,Map<id,Schema.Address> newAddressMap,Map<id,Schema.Address> oldAddressMap){
        //helper.updateLocationOnAddress(newAddressList,oldAddressMap);
        helper.activateOrderOnAddressStatus(newAddressList,newAddressMap,oldAddressMap);
    }
}