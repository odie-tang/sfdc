/**
 * Copyright (c), odie.tang (guihuatang@hotmail.com)
 * All rights reserved.
 *
 * Redistribution and use in source and package forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in package form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the Odie Tang nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
* This is an enterprise trigger base that manages the DML actions in a scalable, efficient, flexible and simple way.
* Tiger is a short name of Trigger. Note: this is not so-called "pattern" - TriggerHandler
* Advantages: 
*   1.Each DML action can be self sufficient and independent of each other, which simply scales
*   2.The sequence of execution can be defined, and defined at the metadata level - @TriggerActions__mdt
*   3.The trigger actions can be grouped by sObjects, and then Applications:
*     e.g. if the Account sObject is shared by 3 Apps - Sales, Service & Market, the actions for each App can be grouped into a single record of TriggerActions__mdt. 
*     e.g. if a global company uses the Account in its Sales App, and different regions/countries have their own business processes, the region wise trigger actions can be grouped into the same metadata record. 
*/
public virtual class Tiger {
    
    private static Map<String, Integer> sObjectTriggerCounterMap = new Map<String, Integer>();
    
    private static Map<String, List<String>> actions = new Map<String, List<String>>();
    private static Map<String, List<BeforeInsert>> biActions = new Map<String, List<BeforeInsert>>();
    private static Map<String, List<AfterInsert>> aiActions = new Map<String, List<AfterInsert>>();
    private static Map<String, List<BeforeUpdate>> buActions = new Map<String, List<BeforeUpdate>>();
    private static Map<String, List<AfterUpdate>> auActions = new Map<String, List<AfterUpdate>>();
    private static Map<String, List<BeforeDelete>> bdActions = new Map<String, List<BeforeDelete>>();
    private static Map<String, List<AfterDelete>> adActions = new Map<String, List<AfterDelete>>();
    private static Map<String, List<AfterUndelete>> audActions = new Map<String, List<AfterUndelete>>();

    static{

        fetchAllTriggerActionsMdt();
    }

    public Tiger(){
        addTriggerCount();
    }

    public interface BeforeInsert{
        boolean isInScopeBi(SObject newRecord);
        void handleBi(SObject[] recordsInScope);
    }

    public interface AfterInsert{
        boolean isInScopeAi(SObject newRecord);
        void handleAi(SObject[] recordsInScope);
    }
    public interface BeforeUpdate{
        boolean isInScopeBu(SObject newRecord);
        void handleBu(SObject[] recordsInScope);
    }
    public interface AfterUpdate{
        boolean isInScopeAu(SObject newRecord);
        void handleAu(SObject[] recordsInScope);
    }
    public interface BeforeDelete{
        boolean isInScopeBd(SObject oldRecord);
        void handleBd(SObject[] recordsInScope);
    }
    public interface AfterDelete{
        boolean isInScopeAd(SObject oldRecord);
        void handleAd(SObject[] recordsInScope);
    }
   
    public interface AfterUndelete{
        boolean isInScopeAud(SObject newRecord);
        void handleAud(SObject[] recordsInScope);
    }

    /**
    * The trigger actions metadata are fetched once and are grouped by sObject names, and then are cached by Salesforce ever since;
    * The actions will not be initilized until their sObject's trigger is executed;
    * It loads maximum 50000 records of TriggerActions__mdt, which is a Salesforce governor limit of custom metadata.
    * 
    * A little bit explaination about the TriggerActions__mdt:
    * The @MasterLabel defines the sObject Name. One sObject may have multiple entries of TriggerActions__mdt; 
    * The @DeveloperName is unique, and used for ordering the sequence of executions for a specific sObject defined in @MasterLabel;
    * The @Actions__c is a list of trigger actions that is split by new line character '\\n'; the actions will be executed in the same order as in the @Actions__c field
    */
    private static void fetchAllTriggerActionsMdt(){

        TriggerActions__mdt[] triggerActions = [select MasterLabel, DeveloperName, Actions__c from TriggerActions__mdt where Active__c=true order by MasterLabel, DeveloperName limit 50000];

        for(TriggerActions__mdt tas : triggerActions){

            if(!actions.containsKey(tas.MasterLabel))
                actions.put(tas.MasterLabel, new List<String>());

            actions.get(tas.MasterLabel).addAll(tas.Actions__c.split('\\n'));
        }
      
    }

    
    /**
    * lazy load : init the trigger handler action classes only when the trigger is fired the first time
    */
    private static void initCurrentSObjectTriggerActions(){

        String sObjectName = getSObjectName();

        if(!biActions.containsKey(sObjectName)){
            biActions.put(sObjectName, new List<BeforeInsert>());
            aiActions.put(sObjectName, new List<AfterInsert>());
            buActions.put(sObjectName, new List<BeforeUpdate>());
            auActions.put(sObjectName, new List<AfterUpdate>());
            bdActions.put(sObjectName, new List<BeforeDelete>());
            adActions.put(sObjectName, new List<AfterDelete>());
            audActions.put(sObjectName, new List<AfterUndelete>());
        }

        if(!actions.containsKey(sObjectName)) return;

        for(String actionName : actions.get(sObjectName)){

            Object action = Type.forName(actionName.trim()).newInstance();

            if(action instanceof BeforeInsert)
                biActions.get(sObjectName).add((BeforeInsert)action);

            if(action instanceof AfterInsert)
                aiActions.get(sObjectName).add((AfterInsert)action);
            
            if(action instanceof BeforeUpdate)
                buActions.get(sObjectName).add((BeforeUpdate)action);

            if(action instanceof AfterUpdate)
                auActions.get(sObjectName).add((AfterUpdate)action);
            
            if(action instanceof BeforeDelete)
                bdActions.get(sObjectName).add((BeforeDelete)action);
            
            if(action instanceof AfterDelete)
                adActions.get(sObjectName).add((AfterDelete)action);
            
            if(action instanceof AfterUndelete)
                audActions.get(sObjectName).add((AfterUndelete)action);
        }

        actions.remove(sObjectName);

    }

    public void fire(){

        initCurrentSObjectTriggerActions();
        
        String sObjectName = getSObjectName();

        if(trigger.isbefore){
            if(trigger.isInsert){
                for(BeforeInsert action : biActions.get(sObjectName)){
                    handle(action);
                }
            }
            else if(trigger.isUpdate){
                for(BeforeUpdate action : buActions.get(sObjectName)){                    
                    handle(action);
                }
            }
            else if(trigger.isDelete){
                for(BeforeDelete action : bdActions.get(sObjectName)){
                   handle(action);
                }
            }
        }
        else{
            if(trigger.isInsert){
                for(AfterInsert action : aiActions.get(sObjectName)){
                    handle(action);
                }
            }
            else if(trigger.isUpdate){
                for(AfterUpdate action : auActions.get(sObjectName)){
                    handle(action);
                }
            }
            else if(trigger.isDelete){
                for(AfterDelete action : adActions.get(sObjectName)){
                    handle(action);
                }
            }
            else if(trigger.isUndelete){
                for(AfterUndelete action : audActions.get(sObjectName)){
                    handle(action);
                }
            }
        }
    }

    private static void handle(BeforeInsert biAction){
        
        SObject[] recordsInScope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(biAction.isInScopeBi(record))
                recordsInScope.add(record);
        }

        if(!recordsInScope.isEmpty())
            biAction.handleBi(recordsInScope);
    }

    private static void handle(AfterInsert aiAction){
        
        SObject[] recordsInScope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(aiAction.isInScopeAi(record))
                recordsInScope.add(record);
        }

        if(!recordsInScope.isEmpty())
            aiAction.handleAi(recordsInScope);
    }

    private static void handle(BeforeUpdate buAction){

        SObject[] recordsInScope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(buAction.isInScopeBu(record))
                recordsInScope.add(record);
        }

        if(!recordsInScope.isEmpty())
            buAction.handleBu(recordsInScope);
    }

    private static void handle(AfterUpdate auAction){

        SObject[] recordsInScope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(auAction.isInScopeAu(record))
                recordsInScope.add(record);
        }

        if(!recordsInScope.isEmpty())
            auAction.handleAu(recordsInScope);
    }

    private static void handle(BeforeDelete bdAction){

        SObject[] recordsInScope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(bdAction.isInScopeBd(record))
                recordsInScope.add(record);
        }

        if(!recordsInScope.isEmpty())
            bdAction.handleBd(recordsInScope);
    }

    private static void handle(AfterDelete adAction){

        SObject[] recordsInScope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(adAction.isInScopeAd(record))
                recordsInScope.add(record);
        }

        if(!recordsInScope.isEmpty())
            adAction.handleAd(recordsInScope);
    }

    private static void handle(AfterUndelete audAction){

        SObject[] recordsInScope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(audAction.isInScopeAud(record))
                recordsInScope.add(record);
        }

        if(!recordsInScope.isEmpty())
            audAction.handleAud(recordsInScope);
    }

    public Integer getTriggerLevel(){

        return sObjectTriggerCounterMap.get(getSObjectName());
    }
    
    private static void addTriggerCount(){

        String sObjectName = getSObjectName();

        if(!sObjectTriggerCounterMap.containsKey(sObjectName)){

            sObjectTriggerCounterMap.put(sObjectName, 1);

            return;
        }

        sObjectTriggerCounterMap.put(sObjectName, sObjectTriggerCounterMap.get(sObjectName) + 1);
    }

    private static String getSObjectName(){

        List<SObject> recordsInTrigger = trigger.new != null ? trigger.new : trigger.old;

        return recordsInTrigger.getSObjectType().getDescribe().getName();
    }
}