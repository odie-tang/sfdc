/**
 * Blog: https://odietang.blogspot.com/2020/08/introduction-to-tiger.html
 * 
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
global virtual class Tiger {

    private String context;
    private Boolean allowSkipTiger = true;
    
    private static Map<String, Set<String>> contextsAlreadyRunBi  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAi  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunBu  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAu  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunBd  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAd  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAud = new Map<String, Set<String>>();
    
    private List<BeforeInsert> actionersBi = new List<BeforeInsert>();
    private List<AfterInsert> actionersAi = new List<AfterInsert>();
    private List<BeforeUpdate> actionersBu = new List<BeforeUpdate>();
    private List<AfterUpdate> actionersAu = new List<AfterUpdate>();
    private List<BeforeDelete> actionersBd = new List<BeforeDelete>();
    private List<AfterDelete> actionersAd = new List<AfterDelete>();
    private List<AfterUndelete> actionersAud = new List<AfterUndelete>();

    global interface Recursive{}

    global interface Actioner{}

    global interface Skipable{
        String customPermission();
    }
    global interface BeforeInsert extends Actioner{
        boolean inScopeBi(SObject newRecord);
        void processBi(SObject[] scope);
    }
    global interface AfterInsert extends Actioner{
        boolean inScopeAi(SObject newRecord);
        void processAi(SObject[] scope);
    }
    global interface BeforeUpdate extends Actioner{
        boolean inScopeBu(SObject newRecord);
        void processBu(SObject[] scope);
    }
    global interface AfterUpdate extends Actioner{
        boolean inScopeAu(SObject newRecord);
        void processAu(SObject[] scope);
    }
    global interface BeforeDelete extends Actioner{
        boolean inScopeBd(SObject oldRecord);
        void processBd(SObject[] scope);
    }
    global interface AfterDelete extends Actioner{
        boolean inScopeAd(SObject oldRecord);
        void processAd(SObject[] scope);
    }
    global interface AfterUndelete extends Actioner{
        boolean inScopeAud(SObject newRecord);
        void processAud(SObject[] scope);
    }

    global Tiger(String[] actionerClasses){

        for(String actionerClass : actionerClasses){

            Actioner actioner = (Actioner)Type.forName(actionerClass).newInstance();

            addActioner(actioner);
        }
    }

    global Tiger(Actioner[] actioners){

        for(Actioner actioner : actioners){
            
            addActioner(actioner);
        }
    }

    global Tiger(String[] actionerClasses, String context){

        this(actionerClasses);

        this.context = context;        
    }

    global Tiger(Actioner[] actioners, String context){

        this(actioners);

        this.context = context;
    }

    private void addActioner(Actioner actioner){
        
        if(actioner instanceof BeforeInsert)
            actionersBi.add((BeforeInsert)actioner);

        if(actioner instanceof AfterInsert)
            actionersAi.add((AfterInsert)actioner);
        
        if(actioner instanceof BeforeUpdate)
            actionersBu.add((BeforeUpdate)actioner);

        if(actioner instanceof AfterUpdate)
            actionersAu.add((AfterUpdate)actioner);
        
        if(actioner instanceof BeforeDelete)
            actionersBd.add((BeforeDelete)actioner);
        
        if(actioner instanceof AfterDelete)
            actionersAd.add((AfterDelete)actioner);
        
        if(actioner instanceof AfterUndelete)
            actionersAud.add((AfterUndelete)actioner);
    }

    global void disallowSkipTiger(){

        this.allowSkipTiger = false;
    }

    global void fire(){

        if(this.allowSkipTiger && hasSkipTigerCustomPermission()) return;

        if(trigger.isBefore){
            
            if(trigger.isInsert){

                executeBeforeInsert();
            }
            else if(trigger.isUpdate){

                executeBeforeUpdate();
            }
            else if(trigger.isDelete){

                executeBeforeDelete();
            }
        }
        else{
            if(trigger.isInsert){
                
                executeAfterInsert();
            }
            else if(trigger.isUpdate){
                
                executeAfterUpdate();
            }
            else if(trigger.isDelete){
                
                executeAfterDelete();
            }
            else if(trigger.isUndelete){

                executeAfterUndelete();
            }
        }
    }

    private void executeBeforeInsert(){
        
        System.debug('Executing before insert trigger for ' + getSObjectName());

        for(BeforeInsert actioner : actionersBi){

            if(isExecutable(actioner, contextsAlreadyRunBi))
                execute(actioner);
        }

        markAlreadyRun(contextsAlreadyRunBi);
        
    }
    
    private void executeBeforeUpdate(){

        System.debug('Executing before update trigger for ' + getSObjectName());
            
        for(BeforeUpdate actioner : actionersBu){

            if(isExecutable(actioner, contextsAlreadyRunBu))
                execute(actioner);
        }

        markAlreadyRun(contextsAlreadyRunBu);
    }

    private void executeBeforeDelete(){

        System.debug('Executing before delete trigger for ' + getSObjectName());

        for(BeforeDelete actioner : actionersBd){

            if(isExecutable(actioner, contextsAlreadyRunBd))
                execute(actioner);
        }

        markAlreadyRun(contextsAlreadyRunBd);
    }
    
    private void executeAfterInsert(){

        System.debug('Executing after insert trigger for ' + getSObjectName());

        for(AfterInsert actioner : actionersAi){

            if(isExecutable(actioner, contextsAlreadyRunAi))
                execute(actioner);
        }

        markAlreadyRun(contextsAlreadyRunAi);
    }
    
    private void executeAfterUpdate(){

        System.debug('Executing after update trigger for ' + getSObjectName());

        for(AfterUpdate actioner : actionersAu){

            if(isExecutable(actioner, contextsAlreadyRunAu))
                execute(actioner);
        }

        markAlreadyRun(contextsAlreadyRunAu);
    }
    
    private void executeAfterDelete(){

        System.debug('Executing after delete trigger for ' + getSObjectName());

        for(AfterDelete actioner : actionersAd){

            if(isExecutable(actioner, contextsAlreadyRunAd))
                execute(actioner);
        }

        markAlreadyRun(contextsAlreadyRunAd);
    }

    private void executeAfterUndelete(){

        System.debug('Executing after undelete trigger for ' + getSObjectName());

        for(AfterUndelete actioner : actionersAud){

            if(isExecutable(actioner, contextsAlreadyRunAud))
                execute(actioner);
        }

        markAlreadyRun(contextsAlreadyRunAud);
    }

    private void execute(BeforeInsert actioner){
        
        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeBi(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processBi(scope);
    }

    private void execute(AfterInsert actioner){
        
        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAi(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAi(scope);
    }

    private void execute(BeforeUpdate actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeBu(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processBu(scope);
    }

    private void execute(AfterUpdate actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAu(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAu(scope);
    }

    private void execute(BeforeDelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(actioner.inScopeBd(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processBd(scope);
    }

    private void execute(AfterDelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(actioner.inScopeAd(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAd(scope);
    }

    private void execute(AfterUndelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAud(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAud(scope);
    }

    private Boolean isExecutable(Actioner actioner, Map<String, Set<String>> contextAlreadyRun){

        return ((actioner instanceof Recursive) || !alreadyRun(contextAlreadyRun)) && !skipActioner(actioner);
    }

    private Boolean alreadyRun(Map<String, Set<String>> contextAlreadyRun){

        String sObjectName = getSObjectName();

        if(!contextAlreadyRun.containsKey(sObjectName)){

            return false;
        }
        else{

            return contextAlreadyRun.get(sObjectName).contains(context);
        }
    }

    private void markAlreadyRun(Map<String, Set<String>> contextAlreadyRun){

        String sObjectName = getSObjectName();

        if(!contextAlreadyRun.containsKey(sObjectName)){

            contextAlreadyRun.put(sObjectName, new Set<String>());
        }

        contextAlreadyRun.get(sObjectName).add(context);
    }

    private Boolean hasSkipTigerCustomPermission(){

        String customPermissionBase = 'SKIP_TIGER_' + getSObjectName();

        String customPermissionToSkip =  context == null ? customPermissionBase : customPermissionBase + '_' + context;

        return FeatureManagement.checkPermission(customPermissionToSkip);
    }

    private Boolean skipActioner(Actioner actioner){

        if(actioner instanceof Skipable){

            Skipable skipable = (Skipable)actioner;

            return FeatureManagement.checkPermission(skipable.customPermission());
        }

        return false;
    }


    private static String getSObjectName(){

        List<SObject> recordsInTrigger = trigger.new != null ? trigger.new : trigger.old;

        return recordsInTrigger.getSObjectType().getDescribe().getName();
    }
}