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
    
    private static Set<String> sObjectsAlreadyRunBi = new Set<String>();
    private static Set<String> sObjectsAlreadyRunAi = new Set<String>();
    private static Set<String> sObjectsAlreadyRunBu = new Set<String>();
    private static Set<String> sObjectsAlreadyRunAu = new Set<String>();
    private static Set<String> sObjectsAlreadyRunBd = new Set<String>();
    private static Set<String> sObjectsAlreadyRunAd = new Set<String>();
    private static Set<String> sObjectsAlreadyRunAud = new Set<String>();
    
    private static Map<String, List<BeforeInsert>> actionersBi = new Map<String, List<BeforeInsert>>();
    private static Map<String, List<AfterInsert>> actionersAi = new Map<String, List<AfterInsert>>();
    private static Map<String, List<BeforeUpdate>> actionersBu = new Map<String, List<BeforeUpdate>>();
    private static Map<String, List<AfterUpdate>> actionersAu = new Map<String, List<AfterUpdate>>();
    private static Map<String, List<BeforeDelete>> actionersBd = new Map<String, List<BeforeDelete>>();
    private static Map<String, List<AfterDelete>> actionersAd = new Map<String, List<AfterDelete>>();
    private static Map<String, List<AfterUndelete>> actionersAud = new Map<String, List<AfterUndelete>>();

    public interface RunRecursive{}

    public interface Actioner{}

    public interface Skipable{
        String customPermissionName();
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

        if(!actionersBi.containsKey(getSObjectName())){

            initActionersMap();

            for(String actionerClass : actionerClasses){

                Actioner actioner = (Actioner)Type.forName(actionerClass).newInstance();

                addActioner(actioner);
            }
        }
    }

    public Tiger(Actioner[] actioners){

        if(!actionersBi.containsKey(getSObjectName())){

            initActionersMap();

            for(Actioner actioner : actioners){

                addActioner(actioner);
            }
        }
    }

    private void initActionersMap(){

        String sObjectName = getSObjectName();

        actionersBi.put(sObjectName, new List<BeforeInsert>());
        actionersAi.put(sObjectName, new List<AfterInsert>());
        actionersBu.put(sObjectName, new List<BeforeUpdate>());
        actionersAu.put(sObjectName, new List<AfterUpdate>());
        actionersBd.put(sObjectName, new List<BeforeDelete>());
        actionersAd.put(sObjectName, new List<AfterDelete>());
        actionersAud.put(sObjectName, new List<AfterUndelete>());
    }

    private void addActioner(Actioner actioner){

        String sObjectName = getSObjectName();

        if(actioner instanceof BeforeInsert)
            actionersBi.get(sObjectName).add((BeforeInsert)actioner);

        if(actioner instanceof AfterInsert)
            actionersAi.get(sObjectName).add((AfterInsert)actioner);
        
        if(actioner instanceof BeforeUpdate)
            actionersBu.get(sObjectName).add((BeforeUpdate)actioner);

        if(actioner instanceof AfterUpdate)
            actionersAu.get(sObjectName).add((AfterUpdate)actioner);
        
        if(actioner instanceof BeforeDelete)
            actionersBd.get(sObjectName).add((BeforeDelete)actioner);
        
        if(actioner instanceof AfterDelete)
            actionersAd.get(sObjectName).add((AfterDelete)actioner);
        
        if(actioner instanceof AfterUndelete)
            actionersAud.get(sObjectName).add((AfterUndelete)actioner);
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

    private static void executeBeforeInsert(){

        if(trigger.isBefore && trigger.isInsert){

            String sObjectName = getSObjectName();

            for(BeforeInsert actioner : actionersBi.get(sObjectName)){
            
                Boolean isExecutable = ((actioner instanceof RunRecursive) || !sObjectsAlreadyRunBi.contains(sObjectName)) && !skipActioner(actioner);
                
                if(isExecutable) execute(actioner);
            }
            
            sObjectsAlreadyRunBi.add(sObjectName);
        }
    }

    private static void executeBeforeUpdate(){

        if(trigger.isBefore && trigger.isUpdate){

            String sObjectName = getSObjectName();
                
            for(BeforeUpdate actioner : actionersBu.get(sObjectName)){

                Boolean isExecutable = ((actioner instanceof RunRecursive) || !sObjectsAlreadyRunBu.contains(sObjectName)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            sObjectsAlreadyRunBu.add(sObjectName);
        }
    }

    private static void executeBeforeDelete(){

        if(trigger.isBefore && trigger.isDelete){

            String sObjectName = getSObjectName();

            for(BeforeDelete actioner : actionersBd.get(sObjectName)){

                Boolean isExecutable = ((actioner instanceof RunRecursive) || !sObjectsAlreadyRunBd.contains(sObjectName)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            sObjectsAlreadyRunBd.add(sObjectName);
        }
    }
    
    private static void executeAfterInsert(){

        String sObjectName = getSObjectName();

        if(trigger.isAfter && trigger.isInsert){

            for(AfterInsert actioner : actionersAi.get(sObjectName)){

                Boolean isExecutable = ((actioner instanceof RunRecursive) || !sObjectsAlreadyRunAi.contains(sObjectName)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            sObjectsAlreadyRunAi.add(sObjectName);
        }
    }
    
    private static void executeAfterUpdate(){

        if(trigger.isAfter && trigger.isUpdate){

            String sObjectName = getSObjectName();

            for(AfterUpdate actioner : actionersAu.get(sObjectName)){

                Boolean isExecutable = ((actioner instanceof RunRecursive) || !sObjectsAlreadyRunAu.contains(sObjectName)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            sObjectsAlreadyRunAu.add(sObjectName);
        }
    }
    
    private static void executeAfterDelete(){

        if(trigger.isAfter && trigger.isDelete){

            String sObjectName = getSObjectName();

            for(AfterDelete actioner : actionersAd.get(sObjectName)){

                Boolean isExecutable = ((actioner instanceof RunRecursive) || !sObjectsAlreadyRunAd.contains(sObjectName)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            sObjectsAlreadyRunAd.add(sObjectName);
        }
    }

    private static void executeAfterUndelete(){

        if(trigger.isAfter && trigger.isUndelete){

            String sObjectName = getSObjectName();

            for(AfterUndelete actioner : actionersAud.get(sObjectName)){

                Boolean isExecutable = ((actioner instanceof RunRecursive) || !sObjectsAlreadyRunAud.contains(sObjectName)) && !skipActioner(actioner);

                if(isExecutable) execute(actioner);
            }

            sObjectsAlreadyRunAud.add(sObjectName);
        }
    }

    private static void execute(BeforeInsert actioner){
        
        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeBi(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processBi(scope);
    }

    private static void execute(AfterInsert actioner){
        
        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAi(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAi(scope);
    }

    private static void execute(BeforeUpdate actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeBu(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processBu(scope);
    }

    private static void execute(AfterUpdate actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAu(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAu(scope);
    }

    private static void execute(BeforeDelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(actioner.inScopeBd(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processBd(scope);
    }

    private static void execute(AfterDelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(actioner.inScopeAd(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAd(scope);
    }

    private static void execute(AfterUndelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAud(record))
                scope.add(record);
        }

        if(!scope.isEmpty())
            actioner.processAud(scope);
    }

    private static Boolean hasSkipTigerCustomPermission(){

        String skipAll = 'SKIP_TIGER_ALL';

        String skipCurrentSObject = 'SKIP_TIGER_' + getSObjectName();

        return FeatureManagement.checkPermission(skipAll) || FeatureManagement.checkPermission(skipCurrentSObject);
    }

    private static Boolean skipActioner(Actioner actioner){

        if(actioner instanceof Skipable){

            Skipable skipable = (Skipable)actioner;

            return FeatureManagement.checkPermission(skipable.customPermissionName());
        }

        return false;
    }


    private static String getSObjectName(){

        List<SObject> recordsInTrigger = trigger.new != null ? trigger.new : trigger.old;

        return recordsInTrigger.getSObjectType().getDescribe().getName();
    }
}