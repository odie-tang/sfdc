/*
*
* Add this test class, the implementation of Tiger Actioners to an Apex Trigger, e.g. the Account.trigger.
* Then Run Test thru the class TigerTest,
* which creates Account records, updates, deletes and undeletes them to cover all the trigger events.
*
*/
public with sharing class TigerActionerTest implements 
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
        System.assert(Trigger.operationType == TriggerOperation.BEFORE_INSERT);
        return Test.isRunningTest();
    }
    public void processBeforeInsert(SObject[] scope){
        System.assert(Trigger.operationType == TriggerOperation.BEFORE_INSERT);
        process(scope);
    }
    public boolean inScopeAfterInsert(SObject newRecord){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_INSERT);
        return Test.isRunningTest();
    }
    public void processAfterInsert(SObject[] scope){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_INSERT);
        process(scope);
    }
    public boolean inScopeBeforeUpdate(SObject newRecord){
        System.assert(Trigger.operationType == TriggerOperation.BEFORE_UPDATE);

        if(TigerTest.testing){

            System.assert(UtilTrigger.sObjectName() == 'Account');
            System.assert(UtilTrigger.anyFieldChanged(newRecord, new String[]{'Name', 'AccountNumber'}));
            System.assert(UtilTrigger.fieldChanged(newRecord, 'AccountNumber'));
            System.assertEquals(UtilTrigger.fieldChanged(newRecord, 'Name'), false);
            System.assert(UtilTrigger.fieldChanged(newRecord, 'AccountNumber', 'abc', 'abc_update'));
            System.assert(UtilTrigger.fieldChangedFrom(newRecord, 'AccountNumber', 'abc'));
            System.assert(UtilTrigger.fieldChangedFromAnyOldValue(newRecord, 'AccountNumber', new String[]{'abc','bcd'}));
            System.assertEquals(UtilTrigger.fieldChangedFromAnyOldValue(newRecord, 'AccountNumber', new String[]{'bcd'}), false);
            System.assertEquals(UtilTrigger.fieldChangedToAnyNewValue(newRecord, 'AccountNumber', new String[]{'bcd', 'a'}), false);
            System.assert(UtilTrigger.fieldChangedToAnyNewValue(newRecord, 'AccountNumber', new String[]{'bcd', 'abc_update'}));
            System.assert(UtilTrigger.fieldChanged(newRecord, 'AccountNumber', 'abc', 'abc_update'));
            System.assert(UtilTrigger.fieldChanged(newRecord, 'AccountNumber', new String[]{'abc'}, new String[]{'abc_update'}));
            System.assert(UtilTrigger.fieldChanged(newRecord, 'AccountNumber', 'abc', new String[]{'abc_update'}));
        }
        
        return Test.isRunningTest();
    }
    public void processBeforeUpdate(SObject[] scope){
        System.assert(Trigger.operationType == TriggerOperation.BEFORE_UPDATE);
        process(scope);
    }
    public boolean inScopeAfterUpdate(SObject newRecord){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_UPDATE);
        return Test.isRunningTest();
    }
    public void processAfterUpdate(SObject[] scope){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_UPDATE);
        process(scope);
    }
    public boolean inScopeBeforeDelete(SObject oldRecord){
        System.assert(Trigger.operationType == TriggerOperation.BEFORE_DELETE);
        return Test.isRunningTest();
    }
    public void processBeforeDelete(SObject[] scope){
        System.assert(Trigger.operationType == TriggerOperation.BEFORE_DELETE);
        process(scope);
    }
    public boolean inScopeAfterDelete(SObject oldRecord){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_DELETE);
        return Test.isRunningTest();
    }
    public void processAfterDelete(SObject[] scope){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_DELETE);
        process(scope);
    }
    public boolean inScopeAfterUndelete(SObject newRecord){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_UNDELETE);
        return Test.isRunningTest();
    }
    public void processAfterUndelete(SObject[] scope){
        System.assert(Trigger.operationType == TriggerOperation.AFTER_UNDELETE);
        process(scope);
    }

    private void process(SObject[] scope){
        System.assert(!scope.isEmpty());
    }

}