/**
 * 
 * Blog: https://odietang.blogspot.com/2020/08/introduction-to-tiger.html
 * 
 * Source Code: 
 * https://github.com/odie-tang/sfdc/blob/master/force-app/main/default/classes/Tiger.cls
 * 
 * Copyright (c), odie.tang
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial
 * portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
 * BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
**/


/**
 * This class implements the following business requirement - 
 *      when an Account or multiple Accounts are created and the Industry is "Government", 
 *      or are updated and the Industry is changed to "Government" from a different value, 
 *      set the Special_Handling__c to TRUE and create a Task assigned to the Account owner for each Account.
 * 
 * 1. Setting Special_Handling__c should be taken care of in the before triggers - BeforeInsert & BeforeUpdate
 * 2. Creating Tasks should be processed in the after triggers - AfterInsert & AfterUpdate.
 * 3. The before trigger and after trigger share the same "inScope" check for a particular trigger event, e.g. inScopeBeforeInsert vs. inScopeAfterInsert.
 * 4. The insert trigger and update trigger share the same "process" methods as both of them need to do the same thing for the in-scope Accounts - "setSpecialHandling" & "createTasks".
 * 5. In general, all a developer needs to do using the Tiger framework:
 *      a) Find out which trigger events need to fire the logic, and implement the corresponding Tiger.Actioner interface
 *      b) Define what is the "inScope" criteria and "process" logic for each Tiger.Actioner interface
 *      c) Add the class to the Apex Trigger for executing(e.g. Account.trigger), in the right sequential order along with others. 
 * 6. Benefits:
 *      a) The logics for each different trigger event is bounded to interfaces, developers no longer need to check the events using if...else... and pass parameters mannually
 *      b) A single apex class can implement multiple trigger events, allowing related work to be cohesively grouped in a single place
 *      c) Each individual Apex class implementing Tiger.Actioner is standalone with their own "inScope" definition, having minimum impact to the others, which solves the main common problem of writting Apex triggers.
 *      d) Controll the sequence of execution while adding the class instance to the Apex Trigger easily
 *      e) By default, recursion is avoided for update triggers, less worry to getting into recursion issues
 *      f) Dynamically hooked up with Custom Permissions, allowing to controll Skipability using standard Permission Sets/Permission Set Groups in a more flexible way, without introducing extra mechnism like the Custom Metadata or Custom Settings.
 * 
 */
public with sharing class AccountTgIndustryGovernmentManager implements 
    Tiger.BeforeInsert, Tiger.AfterInsert, Tiger.BeforeUpdate, Tiger.AfterUpdate, Tiger.Skipable{

    /**
     * This method is part of the Tiger.BeforeInsert interface, and
     * will be automatically checked for each Account of the Trigger.new in the Before Insert trigger.
     * Developers just need to let the framework know - for each record in the Trigger.new, what is the "inScope" criteria,
     * then process the in scope records in the corresponding "process" method.
     * 
     * In this example, when an Account is created and its Industry equals to "Government", it is in the scope.
     */
    public boolean inScopeBeforeInsert(SObject newRecord){

        Account account = (Account)newRecord;

        return account.Industry == 'Government';
    }

    /**
     * This method is part of the Tiger.BeforeInsert interface, and
     * will be automatically executed when Accounts are insterted and passed the "inScopeBeforeInsert" check in the Before Insert trigger.
     * 
     * In this example, it calls the method "setSpecialHandling" which sets the Special_Handling__c to true for all Accounts in the scope. 
     * 
     * "setSpecialHandling" is a reusable method that is used in the "processBeforeUpdate" as well.
     */
    public void processBeforeInsert(SObject[] scope){

        setSpecialHandling((Account[])scope);
    }
    
    /**
     * The method is part of the Tiger.AfterInsert interface, will be executed automatically in the After Insert trigger.
     * 
     * In this example, it uses the same logic as in the "inScopeBeforeInsert" to check the scope of a record.
     * 
     */
    public boolean inScopeAfterInsert(SObject newRecord){

        return inScopeBeforeInsert(newRecord);
    }

    /**
     * The method is part of the Tiger.AfterInsert interface, will be executed automatically in the After Insert trigger.
     * 
     * In this example, it creates a Task for each Account in the scope by invoking the reusable method - "createTasks".
     * 
     */
    public void processAfterInsert(SObject[] scope){

        createTasks((Account[])scope);
    }
    
    /**
     * The method is part of the Tiger.BeforeUpdate interface, will be executed automatically in the Before Update trigger.
     * 
     * In this example, it checks each record in the Trigger.new to see if the Industry field has been changed to "Government" from a different value.
     * 
     */
    public boolean inScopeBeforeUpdate(SObject newRecord){

        return UtilTrigger.fieldChangedTo(newRecord, 'Industry', 'Government');
    }
    
    /**
     * This method is part of the Tiger.BeforeUpdate interface, and
     * will be automatically executed when Accounts are insterted and passed the "inScopeBeforeUpdate" check in the Before Update trigger.
     * 
     * In this example, it calls the method "setSpecialHandling" which sets the Special_Handling__c to true for all Accounts in the scope. 
     * 
     * "setSpecialHandling" is a reusable method that is used in the "processBeforeInsert" as well.
     */
    public void processBeforeUpdate(SObject[] scope){

        setSpecialHandling((Account[])scope);
    }
        
    /**
     * The method is part of the Tiger.AfterUpdate interface, will be executed automatically in the After Update trigger.
     * 
     * In this example, it uses the same logic as in the "inScopeBeforeUpdate" to check the scope of a record.
     * 
     */
    public boolean inScopeAfterUpdate(SObject newRecord){

        return inScopeBeforeUpdate(newRecord);
    }
    
    /**
     * The method is part of the Tiger.AfterInsert interface, will be executed automatically in the After Update trigger.
     * 
     * In this example, it creates a Task for each Account in the scope by invoking the reusable method - "createTasks".
     * 
     */
    public void processAfterUpdate(SObject[] scope){

        createTasks((Account[])scope);
    }
    
    /**
     * Sets the Special_Handling__c to true for each Account in the scope.
     * 
     * This is an in-memory field value assignment in the Before triggers, without having to make DMLs calls.
     */
    private void setSpecialHandling(Account[] accounts){

        for(Account account : accounts){

            account.Special_Handling__c = true;
        }
    }

    /**
     * Creates a Task for each Account in the scope in the bulkified manner. 
     * 
     * This method is invoked in the After triggers, where the Accounts always have their ID available, 
     * have already passed the necessary validations and are saved to the database before Salesforce making the commit.
     */
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
        ret.Description = 'Set up a meeting.';
        ret.ActivityDate = System.today().addDays(7);

        return ret;
    }
    
    /**
     * If the running user has the custom permission "Super_Power", the class will be skipped during trigger execution.
     */
    public String customPermission(){

        return 'Super_Power';
    }
}