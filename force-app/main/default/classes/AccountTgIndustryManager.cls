public with sharing class AccountTgIndustryManager implements 
    Tiger.BeforeInsert, Tiger.AfterInsert, Tiger.BeforeUpdate, Tiger.AfterUpdate{

    
    public boolean inScopeBeforeInsert(SObject newRecord){

        Account account = (Account)newRecord;

        return account.Industry == 'Government';
    }

    public void processBeforeInsert(SObject[] scope){

        setSpecialHandling((Account[])scope);
    }
    
    public boolean inScopeAfterInsert(SObject newRecord){

        return inScopeBeforeInsert(newRecord);
    }
    
    public void processAfterInsert(SObject[] scope){

        createTasks((Account[])scope);
    }
    
    public boolean inScopeBeforeUpdate(SObject newRecord){

        return UtilTrigger.fieldChangedTo(newRecord, 'Industry', 'Government');
    }
    
    public void processBeforeUpdate(SObject[] scope){

        setSpecialHandling((Account[])scope);
    }
    
    public boolean inScopeAfterUpdate(SObject newRecord){

        return inScopeBeforeUpdate(newRecord);
    }
    
    public void processAfterUpdate(SObject[] scope){

        createTasks((Account[])scope);
    }
    
    private void setSpecialHandling(Account[] accounts){

        for(Account account : accounts){

            account.Special_Handling__c = true;
        }
    }

    private void createTasks(Account[] accounts){

        Task[] tasks = new Task[]{};

        for(Account account : accounts){
            
            tasks.add(newTask(account));
        }

        insert tasks;
    }

    private Task newTask(Account account){

        Task ret = new Task();

        ret.Subject = 'Follow Up with the Government Agent';
        ret.Status = 'In Progress';
        ret.Type = 'Meeting';
        ret.WhatId = account.Id;
        ret.OwnerId = account.OwnerId;

        return ret;
    }
}