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
public virtual class Tiger {

    private String context;
    private Boolean allowSkipTiger;
    
    private static Set<String> contextsAlreadyRunBi = new Set<String>();
    private static Set<String> contextsAlreadyRunAi = new Set<String>();
    private static Set<String> contextsAlreadyRunBu = new Set<String>();
    private static Set<String> contextsAlreadyRunAu = new Set<String>();
    private static Set<String> contextsAlreadyRunBd = new Set<String>();
    private static Set<String> contextsAlreadyRunAd = new Set<String>();
    private static Set<String> contextsAlreadyRunAud = new Set<String>();
    
    private List<BeforeInsert> actionersBi = new List<BeforeInsert>();
    private List<AfterInsert> actionersAi = new List<AfterInsert>();
    private List<BeforeUpdate> actionersBu = new List<BeforeUpdate>();
    private List<AfterUpdate> actionersAu = new List<AfterUpdate>();
    private List<BeforeDelete> actionersBd = new List<BeforeDelete>();
    private List<AfterDelete> actionersAd = new List<AfterDelete>();
    private List<AfterUndelete> actionersAud = new List<AfterUndelete>();

    public interface Recursive{}

    public interface Actioner{}

    public interface Skipable{
        String customPermission();
    }
    public interface BeforeInsert extends Actioner{
        boolean inScopeBi(SObject newRecord);
        void processBi(SObject[] scope);
    }
    public interface AfterInsert extends Actioner{
        boolean inScopeAi(SObject newRecord);
        void processAi(SObject[] scope);
    }
    public interface BeforeUpdate extends Actioner{
        boolean inScopeBu(SObject newRecord);
        void processBu(SObject[] scope);
    }
    public interface AfterUpdate extends Actioner{
        boolean inScopeAu(SObject newRecord);
        void processAu(SObject[] scope);
    }
    public interface BeforeDelete extends Actioner{
        boolean inScopeBd(SObject oldRecord);
        void processBd(SObject[] scope);
    }
    public interface AfterDelete extends Actioner{
        boolean inScopeAd(SObject oldRecord);
        void processAd(SObject[] scope);
    }
    public interface AfterUndelete extends Actioner{
        boolean inScopeAud(SObject newRecord);
        void processAud(SObject[] scope);
    }

    public Tiger(String[] actionerClasses){

        this(actionerClasses, getSObjectName(), true);
    }

    public Tiger(Actioner[] actioners){

        this(actioners, getSObjectName(), true);
    }

    public Tiger(String[] actionerClasses, String context, Boolean allowSkipTiger){

        this.context = context;

        this.allowSkipTiger = allowSkipTiger;

        for(String actionerClass : actionerClasses){

            Actioner actioner = (Actioner)Type.forName(actionerClass).newInstance();

            addActioner(actioner);
        }
    }

    public Tiger(Actioner[] actioners, String context,  Boolean allowSkipTiger){

        this.context = context;

        this.allowSkipTiger = allowSkipTiger;

        for(Actioner actioner : actioners){
            
            addActioner(actioner);
        }
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

    public void fire(){

        if(hasSkipTigerCustomPermission()) return;
        
        executeBeforeInsert();

        executeBeforeUpdate();

        executeBeforeDelete();

        executeAfterInsert();

        executeAfterUpdate();

        executeAfterUndelete();
    }

    private void executeBeforeInsert(){

        if(trigger.isBefore && trigger.isInsert){

            System.debug('Executing before insert trigger for ' + getSObjectName());

            for(BeforeInsert actioner : actionersBi){
            
                Boolean isExecutable = ((actioner instanceof Recursive) || !contextsAlreadyRunBi.contains(context)) && !skipActioner(actioner);
                
                if(isExecutable) execute(actioner);
            }
            
            contextsAlreadyRunBi.add(context);
        }
    }

    private void executeBeforeUpdate(){

        if(trigger.isBefore && trigger.isUpdate){

            System.debug('Executing before update trigger for ' + getSObjectName());
                
            for(BeforeUpdate actioner : actionersBu){

                Boolean isExecutable = ((actioner instanceof Recursive) || !contextsAlreadyRunBu.contains(context)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            contextsAlreadyRunBu.add(context);
        }
    }

    private void executeBeforeDelete(){

        if(trigger.isBefore && trigger.isDelete){

            System.debug('Executing before delete trigger for ' + getSObjectName());

            for(BeforeDelete actioner : actionersBd){

                Boolean isExecutable = ((actioner instanceof Recursive) || !contextsAlreadyRunBd.contains(context)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            contextsAlreadyRunBd.add(context);
        }
    }
    
    private void executeAfterInsert(){

        if(trigger.isAfter && trigger.isInsert){

            System.debug('Executing after insert trigger for ' + getSObjectName());

            for(AfterInsert actioner : actionersAi){

                Boolean isExecutable = ((actioner instanceof Recursive) || !contextsAlreadyRunAi.contains(context)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            contextsAlreadyRunAi.add(context);
        }
    }
    
    private void executeAfterUpdate(){

        if(trigger.isAfter && trigger.isUpdate){

            System.debug('Executing after update trigger for ' + getSObjectName());

            for(AfterUpdate actioner : actionersAu){

                Boolean isExecutable = ((actioner instanceof Recursive) || !contextsAlreadyRunAu.contains(context)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            contextsAlreadyRunAu.add(context);
        }
    }
    
    private void executeAfterDelete(){

        if(trigger.isAfter && trigger.isDelete){

            System.debug('Executing after delete trigger for ' + getSObjectName());

            for(AfterDelete actioner : actionersAd){

                Boolean isExecutable = ((actioner instanceof Recursive) || !contextsAlreadyRunAd.contains(context)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            contextsAlreadyRunAd.add(context);
        }
    }

    private void executeAfterUndelete(){

        if(trigger.isAfter && trigger.isUndelete){

            System.debug('Executing after undelete trigger for ' + getSObjectName());

            for(AfterUndelete actioner : actionersAud){

                Boolean isExecutable = ((actioner instanceof Recursive) || !contextsAlreadyRunAud.contains(context)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            contextsAlreadyRunAud.add(context);
        }
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

    private Boolean hasSkipTigerCustomPermission(){

        String skipAll = 'SKIP_TIGER_ALL';

        String skipCurrentSObject = 'SKIP_TIGER_' + getSObjectName();

        return this.allowSkipTiger && (FeatureManagement.checkPermission(skipAll) || FeatureManagement.checkPermission(skipCurrentSObject));
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