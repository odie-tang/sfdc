/**
 * 
 * Blog: https://odietang.blogspot.com/2020/08/introduction-to-tiger.html
 * 
 * Source Code: 
 * https://github.com/odie-tang/sfdc/blob/develop/base/force-app/main/default/classes/Tiger.cls
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
public virtual class Tiger {

    private String context;
    private Boolean allowSkipTiger = true;
    
    private static Map<String, Set<String>> contextsAlreadyRunBeforeInsert  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAfterInsert  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunBeforeUpdate  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAfterUpdate  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunBeforeDelete  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAfterDelete  = new Map<String, Set<String>>();
    private static Map<String, Set<String>> contextsAlreadyRunAfterUndelete = new Map<String, Set<String>>();
    
    private List<BeforeInsert> actionersBeforeInsert = new List<BeforeInsert>();
    private List<AfterInsert> actionersAfterInsert = new List<AfterInsert>();
    private List<BeforeUpdate> actionersBeforeUpdate = new List<BeforeUpdate>();
    private List<AfterUpdate> actionersAfterUpdate = new List<AfterUpdate>();
    private List<BeforeDelete> actionersBeforeDelete = new List<BeforeDelete>();
    private List<AfterDelete> actionersAfterDelete = new List<AfterDelete>();
    private List<AfterUndelete> actionersAfterUndelete = new List<AfterUndelete>();

    public interface Recursive{}

    public interface Actioner{}

    public interface Skipable{
        String customPermission();
    }
    public interface BeforeInsert extends Actioner{
        boolean inScopeBeforeInsert(SObject newRecord);
        void processBeforeInsert(SObject[] scope);
    }
    public interface AfterInsert extends Actioner{
        boolean inScopeAfterInsert(SObject newRecord);
        void processAfterInsert(SObject[] scope);
    }
    public interface BeforeUpdate extends Actioner{
        boolean inScopeBeforeUpdate(SObject newRecord);
        void processBeforeUpdate(SObject[] scope);
    }
    public interface AfterUpdate extends Actioner{
        boolean inScopeAfterUpdate(SObject newRecord);
        void processAfterUpdate(SObject[] scope);
    }
    public interface BeforeDelete extends Actioner{
        boolean inScopeBeforeDelete(SObject oldRecord);
        void processBeforeDelete(SObject[] scope);
    }
    public interface AfterDelete extends Actioner{
        boolean inScopeAfterDelete(SObject oldRecord);
        void processAfterDelete(SObject[] scope);
    }
    public interface AfterUndelete extends Actioner{
        boolean inScopeAfterUndelete(SObject newRecord);
        void processAfterUndelete(SObject[] scope);
    }

    public Tiger(String[] actionerClasses){

        for(String actionerClass : actionerClasses){

            Actioner actioner = (Actioner)Type.forName(actionerClass).newInstance();

            addActioner(actioner);
        }
    }

    public Tiger(Actioner[] actioners){

        for(Actioner actioner : actioners){
            
            addActioner(actioner);
        }
    }

    public Tiger(String[] actionerClasses, String context){

        this(actionerClasses);

        this.context = context;        
    }

    public Tiger(Actioner[] actioners, String context){

        this(actioners);

        this.context = context;
    }

    private void addActioner(Actioner actioner){
        
        if(actioner instanceof BeforeInsert){

            actionersBeforeInsert.add((BeforeInsert)actioner);
        }

        if(actioner instanceof AfterInsert){

            actionersAfterInsert.add((AfterInsert)actioner);
        }
        
        if(actioner instanceof BeforeUpdate){

            actionersBeforeUpdate.add((BeforeUpdate)actioner);
        }

        if(actioner instanceof AfterUpdate){

            actionersAfterUpdate.add((AfterUpdate)actioner);
        }
        
        if(actioner instanceof BeforeDelete){

            actionersBeforeDelete.add((BeforeDelete)actioner);
        }
        
        if(actioner instanceof AfterDelete){

            actionersAfterDelete.add((AfterDelete)actioner);
        }
        
        if(actioner instanceof AfterUndelete){

            actionersAfterUndelete.add((AfterUndelete)actioner);
        }
    }

    public Tiger turnOffSkipTiger(){

        this.allowSkipTiger = false;

        return this;
    }

    public void fire(){

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
        
        if(alreadyRun(contextsAlreadyRunBeforeInsert)){

            for(BeforeInsert actioner : actionersBeforeInsert){
                
                if(isReExecutable(actioner)){

                    execute(actioner);
                }
            }
        }
        else{

            markAlreadyRun(contextsAlreadyRunBeforeInsert);

            for(BeforeInsert actioner : actionersBeforeInsert){
                
                if(!skipActioner(actioner)){

                    execute(actioner);
                }
            }
        }
        
    }
    
    private void executeBeforeUpdate(){

        System.debug('Executing before update trigger for ' + getSObjectName());

        if(alreadyRun(contextsAlreadyRunBeforeUpdate)){

            for(BeforeUpdate actioner : actionersBeforeUpdate){
                
                if(isReExecutable(actioner)){

                    execute(actioner);
                }
            }
        }
        else{

            markAlreadyRun(contextsAlreadyRunBeforeUpdate);

            for(BeforeUpdate actioner : actionersBeforeUpdate){
                
                if(!skipActioner(actioner)){

                    execute(actioner);
                }
            }
        }
    }

    private void executeBeforeDelete(){

        System.debug('Executing before delete trigger for ' + getSObjectName());
        
        if(alreadyRun(contextsAlreadyRunBeforeDelete)){

            for(BeforeDelete actioner : actionersBeforeDelete){
                
                if(isReExecutable(actioner)){

                    execute(actioner);
                }
            }
        }
        else{

            markAlreadyRun(contextsAlreadyRunBeforeDelete);

            for(BeforeDelete actioner : actionersBeforeDelete){
                
                if(!skipActioner(actioner)){

                    execute(actioner);
                }
            }
        }
    }
    
    private void executeAfterInsert(){

        System.debug('Executing after insert trigger for ' + getSObjectName());
        
        if(alreadyRun(contextsAlreadyRunAfterInsert)){

            for(AfterInsert actioner : actionersAfterInsert){
                
                if(isReExecutable(actioner)){

                    execute(actioner);
                }
            }
        }
        else{

            markAlreadyRun(contextsAlreadyRunAfterInsert);

            for(AfterInsert actioner : actionersAfterInsert){
                
                if(!skipActioner(actioner)){

                    execute(actioner);
                }
            }
        }
    }
    
    private void executeAfterUpdate(){

        System.debug('Executing after update trigger for ' + getSObjectName());
        
        if(alreadyRun(contextsAlreadyRunAfterUpdate)){

            for(AfterUpdate actioner : actionersAfterUpdate){
                
                if(isReExecutable(actioner)){

                    execute(actioner);
                }
            }
        }
        else{

            markAlreadyRun(contextsAlreadyRunAfterUpdate);

            for(AfterUpdate actioner : actionersAfterUpdate){
                
                if(!skipActioner(actioner)){

                    execute(actioner);
                }
            }
        }
    }
    
    private void executeAfterDelete(){

        System.debug('Executing after delete trigger for ' + getSObjectName());
        
        if(alreadyRun(contextsAlreadyRunAfterDelete)){

            for(AfterDelete actioner : actionersAfterDelete){
                
                if(isReExecutable(actioner)){

                    execute(actioner);
                }
            }
        }
        else{

            markAlreadyRun(contextsAlreadyRunAfterDelete);

            for(AfterDelete actioner : actionersAfterDelete){
                
                if(!skipActioner(actioner)){

                    execute(actioner);
                }
            }
        }
    }

    private void executeAfterUndelete(){

        System.debug('Executing after undelete trigger for ' + getSObjectName());
        
        if(alreadyRun(contextsAlreadyRunAfterUndelete)){

            for(AfterUndelete actioner : actionersAfterUndelete){
                
                if(isReExecutable(actioner)){

                    execute(actioner);
                }
            }
        }
        else{

            markAlreadyRun(contextsAlreadyRunAfterUndelete);

            for(AfterUndelete actioner : actionersAfterUndelete){
                
                if(!skipActioner(actioner)){

                    execute(actioner);
                }
            }
        }
    }

    private void execute(BeforeInsert actioner){
        
        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeBeforeInsert(record)){

                scope.add(record);
            }
        }

        if(!scope.isEmpty()){

            actioner.processBeforeInsert(scope);
        }
    }

    private void execute(AfterInsert actioner){
        
        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAfterInsert(record)){

                scope.add(record);
            }
        }

        if(!scope.isEmpty()){

            actioner.processAfterInsert(scope);
        }
    }

    private void execute(BeforeUpdate actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeBeforeUpdate(record)){

                scope.add(record);
            }
        }

        if(!scope.isEmpty()){

            actioner.processBeforeUpdate(scope);
        }
    }

    private void execute(AfterUpdate actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAfterUpdate(record)){

                scope.add(record);
            }
        }

        if(!scope.isEmpty()){

            actioner.processAfterUpdate(scope);
        }
    }

    private void execute(BeforeDelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(actioner.inScopeBeforeDelete(record)){

                scope.add(record);
            }
        }

        if(!scope.isEmpty()){

            actioner.processBeforeDelete(scope);
        }
    }

    private void execute(AfterDelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.old){
            
            if(actioner.inScopeAfterDelete(record)){

                scope.add(record);
            }
        }

        if(!scope.isEmpty()){

            actioner.processAfterDelete(scope);
        }
    }

    private void execute(AfterUndelete actioner){

        SObject[] scope = new SObject[]{};
        
        for(SObject record : trigger.new){
            
            if(actioner.inScopeAfterUndelete(record)){

                scope.add(record);
            }
        }

        if(!scope.isEmpty()){

            actioner.processAfterUndelete(scope);
        }
    }

    private Boolean isReExecutable(Actioner actioner){

        return (actioner instanceof Recursive) && !skipActioner(actioner);
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

        String customPermissionToSkip = context == null ? customPermissionBase : customPermissionBase + '_' + context;

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