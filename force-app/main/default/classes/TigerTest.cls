/*
*
* Add this test class, the implementation of Tiger Actioners to the Account trigger.
* Then Run Test thru the static method "test", 
* which creates Account records, updates, deletes and undeletes them to cover all the trigger events.
*
*/
@isTest
public with sharing class TigerTest implements 
    Tiger.BeforeInsert
    ,Tiger.AfterInsert
    ,Tiger.BeforeUpdate
    ,Tiger.AfterUpdate
    ,Tiger.BeforeDelete
    ,Tiger.AfterDelete
    ,Tiger.AfterUndelete
    ,Tiger.Recursive
    ,Tiger.Skipable{

    public String customPermission(){
        return 'abc';
    }
    public boolean inScopeBeforeInsert(SObject newRecord){
        return true;
    }
    public void processBeforeInsert(SObject[] scope){
        process(scope);
    }
    public boolean inScopeAfterInsert(SObject newRecord){
        return true;
    }
    public void processAfterInsert(SObject[] scope){
        process(scope);
    }
    public boolean inScopeBeforeUpdate(SObject newRecord){
        return true;
    }
    public void processBeforeUpdate(SObject[] scope){
        process(scope);
    }
    public boolean inScopeAfterUpdate(SObject newRecord){
        return true;
    }
    public void processAfterUpdate(SObject[] scope){
        process(scope);
    }
    public boolean inScopeBeforeDelete(SObject oldRecord){
        return true;
    }
    public void processBeforeDelete(SObject[] scope){
        process(scope);
    }
    public boolean inScopeAfterDelete(SObject oldRecord){
        return true;
    }
    public void processAfterDelete(SObject[] scope){
        process(scope);
    }
    public boolean inScopeAfterUndelete(SObject newRecord){
        return true;
    }
    public void processAfterUndelete(SObject[] scope){
        process(scope);
    }

    private void process(SObject[] scope){
        System.debug(!scope.isEmpty());
    }

    @isTest
    public static void test(){

        Integer totalNum = 50;

        Account[] accounts = new Account[]{};

        for(Integer i = 0; i < totalNum; i++){
            //replace the record creation accordingly
            Account account = new Account(Name = 'abc' + i); 

            accounts.add(account);
        }

        insert accounts;

        for(Integer i = 0; i < totalNum; i++){

            accounts[i].Name += '_update';
        }

        update accounts;

        delete accounts;

        undelete accounts;
    }
}