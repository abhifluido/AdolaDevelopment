/*
    ***********************************************************************
    Name        : AddressTriggerHelper
    Author      : Ashish Kumar Singh, Fluido AB
    CreatedDate : December 01, 2022
    Description : Helper class for AddressTrigger which have various functions/methods for different functionalities
    ***********************************************************************
*/
public class AddressTriggerHelper {
    
    /*
        Description : Linking Location with Address when its ParentKeyComId__c get changes
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : list of new records, map of new records
        returntype  : N/A
    */
    public void updateLocationOnAddress(list<Schema.Address> newAddressList, Map<id,Schema.Address> oldAddressMap){
        set<string> keyComIds = new set<string>();
        for(Schema.Address addr: newAddressList){
            if(addr.ParentKeyComId__c != null && addr.ParentKeyComId__c != oldAddressMap.get(addr.id).ParentKeyComId__c){
                keyComIds.add(addr.ParentKeyComId__c);
            }
        }
        list<Schema.Address> addressList = new list<Schema.Address>();
        if(keyComIds != null){
            map<string,Schema.Location> locationMap = UTIL_SOQLs.getLocationByKeyComIds(keyComIds);
            for(Schema.Address addr: newAddressList){
                if(locationMap != null && locationMap.ContainsKey(addr.ParentKeyComId__c)){
                    addr.Parent = locationMap.get(addr.ParentKeyComId__c);
                   addressList.add(addr); 
                }
            }
            if(addressList != null && addressList.size() > 0){
                //update addressList;
            }
        }
            
    }
    
    /*
        Description : Activating Order where Address's Status got Approved
        Author      : Ashish Kumar Singh, Fluido AB
        Param       : list of new records, map of new records
        returntype  : N/A
    */
    public void activateOrderOnAddressStatus(list<Schema.Address> newAddressList, Map<id,Schema.Address> newAddressMap, Map<id,Schema.Address> oldAddressMap){
        set<string> addresSet = new set<string>();
        for(Schema.Address add1: newAddressList){
            if(add1.Internal_Status__c != oldAddressMap.get(add1.id).Internal_Status__c && add1.Internal_Status__c == 'Available'){
                addresSet.add(add1.id);
            }
        }
        list<Order> orderList = new list<Order>();
        if(addresSet != null){
            for(Order odr: [Select id,Status,Address__c From Order Where Address__c IN: addresSet]){
                odr.Status = 'Activated';
              orderList.add(odr);  
            }
        }
        if(orderList != null && orderList.size() > 0){
            update orderList;
        }
            
    }
}