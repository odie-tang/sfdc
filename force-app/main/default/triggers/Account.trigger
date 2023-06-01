trigger Account on Account (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    

    if(Test.isRunningTest()){
        
        Tiger.Actioner[] actioners = new Tiger.Actioner[]{
            new TigerTest()
        };
 
        new Tiger(actioners).fire();
    }
    
    
    Tiger.Actioner[] actioners = new Tiger.Actioner[]{
        new AccountTgIndustryGovernmentManager()
    };

    new Tiger(actioners).fire();
}