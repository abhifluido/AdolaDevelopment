Public Class UTIL_SOQLs{
    public static map<string,Schema.Location> getLocationByKeyComIds(Set<string> KeyComIds){
        map<string,Schema.Location> locationMap = new map<string,Schema.Location>();
        if(KeyComIds != null){
            for(Schema.Location loc: [Select id,Keycom_Id__c From Location Where Keycom_Id__c IN: KeyComIds]){
                locationMap.put(loc.Keycom_Id__c, loc);
            }
        }
        return locationMap;
    }
}