trigger Account on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    Tiger.Actioner[] actioners = new Tiger.Actioner[]{
        new TigerActionerTest(),
        new TriggerFieldsFlipper('Close_Open_Opportunities__c'),
        new AccountTgIndustryGovernmentManager(),
        new AccountTgOpportuntiesCloser()
    };

    new Tiger(actioners).fire();
}