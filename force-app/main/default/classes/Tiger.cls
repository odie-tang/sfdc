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

    /**
     * To track whether the Tiger instance has already been executed, to handle recursive exectuions
     * structure: sObjectName => TriggerOperation => Set<Context>
     */
    private static Map<String, Map<TriggerOperation, Set<String>>> contextsAlreadyRun = new Map<String, Map<TriggerOperation, Set<String>>>();
    
    //the sObject Name of the currently executing trigger
    private String sObjectName = getSObjectName();
    /**
     * Use the "context" to separate the business processes on the same object. There can be multiple Tiger instances with their own context.
     * For instance, if the context is set to "Consumer", 
     * only the users with the Custom Permission "TIGER_CONTEXT_Consumer" will be executing the actionsers in the Tiger instance.
     * 
     */
    private String context;
    //Indicate whether the Tiger instance allows skipping via custom permissions.
    private Boolean allowSkipTiger = true;
    //Indicate whether the current user has the skip Tiger permission.
    private Boolean userHasSkipTigerPermission = userHasSkipTigerPermission();
    //Indicate whether the current user does not have the required context permission. It's initialized in the Tiger's constructers with "context" parameter.
    private Boolean userHasNoContextPermission = false;
    //Used to host the Actioners of the currently executing Trigger event.
    private List<Actioner> actioners = new List<Actioner>();

    //BeforeUpdate and AfterUpdate are not recursive by default. To make certain Update Actioners running recursively, implement this interface.
    public interface Recursive{}

    //The super interface for all Trigger Event based interfaces.
    public interface Actioner{}

    /**
     * If an Actioner class implements this interface, no users will be able skip the execution of the class even when they have the SKIP permissions. 
     * 
     * It is typically used when a Data Migration or Integration user needs to skip most of the actioners with some exceptions.
     * 
     */
    public interface NonSkipable{}

    /**
     * If an Actioner class implements this interface, users with the Custom Permission defined in the method "customPermission()"
     * will be able to skip the execution of the class. Add the Custom Permission to Permission Sets or Permission Set Groups and assign 
     * to dedicated users accordingly.
     * 
     * If both NonSkipable and Skipable are implemented at the same time(should avoid that), the Skipable will be ignored.
     */
    public interface Skipable{
        String customPermission();
    }
    /**
     * Trigger Event based interface extends the super interface "Actioner". There are two methods for each Event based interface: 
     * 1. The "inScope" method iterates over each record in the Trigger's context records, collect them if they are determined as "in scope".
     * 2. The process method takes all the records that are in scope passed the "inScope" check above, and handles the logic in bulk manner.
     * 
     * Tips:
     * 1. No need to manually check Trigger's event in the code and pass Trigger variables, the framework will determine in which trigger event the actioner will be executed based on the interface.
     * 2. Focus on defining the logic to check the "scope" for each individual record, instead of iterating over the entire list of records.
     * 3. The parameter's name of the "inScope" method indicates whether the record is from the Trigger.new or Trigger.old, e.g. "newRecord" is from the Trigger.new.
     * 4. In the before insert/update/undelete actioners, field values can be assigned directly to the scoped records, the same as assigning values to Trigger.new records.
     * 5. Salesforce Trigger variables(like Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap) can still be used in any Tiger actioners.
     * 6. Use the utility methods in the UtilTrigger for checking if a field or multiple fields have been changed.
     * 
     */
    public interface BeforeInsert extends Actioner{
        Boolean inScopeBeforeInsert(SObject newRecord);
        void processBeforeInsert(SObject[] scope);
    }
    public interface AfterInsert extends Actioner{
        Boolean inScopeAfterInsert(SObject newRecord);
        void processAfterInsert(SObject[] scope);
    }
    public interface BeforeUpdate extends Actioner{
        Boolean inScopeBeforeUpdate(SObject newRecord);
        void processBeforeUpdate(SObject[] scope);
    }
    public interface AfterUpdate extends Actioner{
        Boolean inScopeAfterUpdate(SObject newRecord);
        void processAfterUpdate(SObject[] scope);
    }
    public interface BeforeDelete extends Actioner{
        Boolean inScopeBeforeDelete(SObject oldRecord);
        void processBeforeDelete(SObject[] scope);
    }
    public interface AfterDelete extends Actioner{
        Boolean inScopeAfterDelete(SObject oldRecord);
        void processAfterDelete(SObject[] scope);
    }
    public interface AfterUndelete extends Actioner{
        Boolean inScopeAfterUndelete(SObject newRecord);
        void processAfterUndelete(SObject[] scope);
    }

    public Tiger(String[] actionerClasses){

        for(String actionerClass : actionerClasses){

            Actioner actioner = (Actioner)Type.forName(actionerClass).newInstance();

            this.actioners.add(actioner);
        }
    }

    public Tiger(Actioner[] actioners){

        for(Actioner actioner : actioners){

            this.actioners.add(actioner);
        }
    }

    public Tiger(String[] actionerClasses, String context){

        this(actionerClasses);

        this.context = context;

        this.userHasNoContextPermission = userHasNoContextPermission();   
    }

    public Tiger(Actioner[] actioners, String context){

        this(actioners);

        this.context = context;

        this.userHasNoContextPermission = userHasNoContextPermission();
    }

    public Tiger turnOffSkipTiger(){

        this.allowSkipTiger = false;

        return this;
    }

    public void fire(){

        debugStartExecution();

        if(Trigger.isBefore){
                
            if(Trigger.isInsert){

                executeBeforeInsert();
            }
            else if(Trigger.isUpdate){

                executeBeforeUpdate();
            }
            else if(Trigger.isDelete){

                executeBeforeDelete();
            }
        }
        else{
            if(Trigger.isInsert){
                
                executeAfterInsert();
            }
            else if(Trigger.isUpdate){
                
                executeAfterUpdate();
            }
            else if(Trigger.isDelete){
                
                executeAfterDelete();
            }
            else if(Trigger.isUndelete){

                executeAfterUndelete();
            }
        }

        debugCompleteExecution();
    }

    private void executeBeforeInsert(){

        for(Actioner actioner : this.actioners){
            
            if(!skipActioner(actioner)){

                execute((BeforeInsert)actioner);
            }
        }
    }
    
    /*
    * Only the "update" actioners are supported in the de-recursion mechnism
    */
    private void executeBeforeUpdate(){

        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if(isReExecutable(actioner)){

                    execute((BeforeUpdate)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if(!skipActioner(actioner)){

                    execute((BeforeUpdate)actioner);
                }
            }
        }
    }

    private void executeBeforeDelete(){

        for(Actioner actioner : this.actioners){
            
            if(!skipActioner(actioner)){

                execute((BeforeDelete)actioner);
            }
        }
    }
    
    private void executeAfterInsert(){

        for(Actioner actioner : this.actioners){
            
            if(!skipActioner(actioner)){

                execute((AfterInsert)actioner);
            }
        }
    }
    
    /*
    * Only the "update" actioners are supported in the de-recursion mechnism
    */
    private void executeAfterUpdate(){
        
        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if(isReExecutable(actioner)){

                    execute((AfterUpdate)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if(!skipActioner(actioner)){

                    execute((AfterUpdate)actioner);
                }
            }
        }
    }
    
    private void executeAfterDelete(){
        
        for(Actioner actioner : this.actioners){
                
            if(!skipActioner(actioner)){

                execute((AfterDelete)actioner);
            }
        }
    }

    private void executeAfterUndelete(){
        
        for(Actioner actioner : this.actioners){
                
            if(!skipActioner(actioner)){

                execute((AfterUpdate)actioner);
            }
        }
    }

    private void debugStartExecution(){

        String objectContext = this.context == null ? this.sObjectName : this.sObjectName + ' in the context " ' + this.context + '"';

        System.debug('Executing ' + Trigger.operationType + ' trigger for ' + objectContext);
    }

    private void debugCompleteExecution(){

        String objectContext = this.context == null ? this.sObjectName : this.sObjectName + ' in the context " ' + this.context + '"';

        System.debug('Completed ' + Trigger.operationType + ' trigger for ' + objectContext);
    }

    private void execute(BeforeInsert actioner){
        
        SObject[] scope = new SObject[]{};
        
        for(SObject record : Trigger.new){
            
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
        
        for(SObject record : Trigger.new){
            
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
        
        for(SObject record : Trigger.new){
            
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
        
        for(SObject record : Trigger.new){
            
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
        
        for(SObject record : Trigger.old){
            
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
        
        for(SObject record : Trigger.old){
            
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
        
        for(SObject record : Trigger.new){
            
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

    private Boolean alreadyRun(){

        return contextsAlreadyRun.get(this.sObjectName)?.get(Trigger.operationType)?.contains(this.context) == true;
    }

    private void markAlreadyRun(){

        Map<TriggerOperation, Set<String>> triggerOperationContexts = contextsAlreadyRun.get(this.sObjectName);

        if(triggerOperationContexts == null){

            triggerOperationContexts = new Map<TriggerOperation, Set<String>>();

            contextsAlreadyRun.put(this.sObjectName, triggerOperationContexts);
        }

        Set<String> contexts = triggerOperationContexts.get(Trigger.operationType);

        if(contexts == null){
            contexts = new Set<String>();
            triggerOperationContexts.put(Trigger.operationType, contexts);
        }

        contexts.add(this.context);
    }

    private Boolean userHasSkipTigerPermission(){

        return FeatureManagement.checkPermission('SKIP_TIGER') 
            || FeatureManagement.checkPermission('SKIP_TIGER_' + this.sObjectName);
    }

    private Boolean userHasNoContextPermission(){
        
        return this.context != null && !FeatureManagement.checkPermission('TIGER_CONTEXT_' + this.context);
    }

    private Boolean skipActioner(Actioner actioner){

        return this.allowSkipTiger 
            && !(actioner instanceof NonSkipable) 
            && (this.userHasSkipTigerPermission || this.userHasNoContextPermission || userHasSkipablePermission(actioner));
    }

    private Boolean userHasSkipablePermission(Actioner actioner){

        if(actioner instanceof Skipable){

            Skipable skipable = (Skipable)actioner;

            return FeatureManagement.checkPermission(skipable.customPermission());
        }

        return false;
    }

    public static String getSObjectName(){

        List<SObject> recordsInTrigger = Trigger.new != null ? Trigger.new : Trigger.old;

        return recordsInTrigger.getSObjectType().getDescribe().getName();
    }
}