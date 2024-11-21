/**
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
public class Tiger {
    /**
    * The unified super interface for all event-based interfaces in this trigger framework. Pass the list of Actioners to the Tiger class's constructors.
    */
    public interface Actioner{}


    /**
     * The 7 event-based interfaces extend the "Actioner" super interface and define two essential methods for each interface:
     * 
     * 1. **inScope Method**: Evaluates each record in the Trigger's context to determine if it is "in scope." Records that meet the criteria are collected for further processing.
     * 2. **process Method**: Performs bulk processing for all records that passed the "inScope" check.
     * 
     * **Implementation Guidelines**:
     * 1. There’s no need to manually check Trigger events or pass Trigger variables. The framework automatically executes the appropriate Trigger event based on the implemented interfaces.
     * 2. Focus on implementing the logic to determine whether individual records are "in scope," rather than iterating through the entire record set.
     * 3. Parameter names in the "inScope" method indicate the source of the record (`Trigger.new` or `Trigger.old`). For example, `newRecord` comes from `Trigger.new`.
     * 4. An Apex class can implement multiple interfaces to handle different Trigger events simultaneously.
     * 5. In before insert/update actioners, you can assign values directly to scoped records (similar to `Trigger.new` records). These changes will be applied before the records are saved to the database.
     * 6. Salesforce Trigger variables (`Trigger.new`, `Trigger.old`, `Trigger.newMap`, `Trigger.oldMap`, etc.) are accessible in all Apex classes running in triggers. Avoid creating unnecessary mechanisms to pass these variables as parameters.
     * 7. Leverage utility methods in the `UtilTrigger` class for common helper functions, such as checking whether one or more fields have changed.
     * 8. Ensure proper execution order when constructing the list of Actioner classes.
     * 9. Keep your trigger logic modular by having each Apex class implement the necessary interfaces and focus on a single task or responsibility.
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
    
    /**
    * Actioners that implement `RunOnce` ensure a TriggerOperation is executed only once for a specific sObject, preventing recursions.
    */
    public interface RunOnce{}



    /**
     * There are three ways to skip Actioners in this framework:
     * 1. Users with the "SKIP_TIGER" custom permission will bypass all Actioners for all objects within the Tiger framework, except those implementing the `NonSkipable` interface. Use this for integration/data migration/batch execution users. 
     * 2. Users with the "SKIP_TIGER_sObjectName" custom permission will bypass all Actioners for the specified "sObjectName," except those implementing the `NonSkipable` interface.
     * 3. Users with custom permissions defined in Actioners that implement the `Skipable` interface can selectively skip those Actioners.
     * 
     * To turn off the skipability, set `allowSkipTiger` to false.
     * 
     */
    public interface Skipable{
        String customPermission();
    }
    public interface NonSkipable{}

    private Boolean allowSkipTiger = true;


    /**
     * Track whether the current trigger operation has been executed for the triggering object, to handle recursive exectuions
     */
    private static Map<String, Set<TriggerOperation>> objectTriggerOperationsAlreadyRun = new Map<String, Set<TriggerOperation>>();
    
    private String sObjectName = getSObjectName();

    private List<Actioner> actioners = new List<Actioner>();


    public Tiger(Actioner[] actioners){

        this.actioners.addAll(actioners);
    }

    public Tiger(String[] actionerClasses){

        for(String actionerClass : actionerClasses){

            Actioner actioner = (Actioner)Type.forName(actionerClass).newInstance();

            this.actioners.add(actioner);
        }
    }

    public Tiger turnOffSkip(){

        this.allowSkipTiger = false;

        return this;
    }

    public void run(){

        System.debug('Executing ' + Trigger.operationType + ' trigger for ' + this.sObjectName);

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

        System.debug('Completed ' + Trigger.operationType + ' trigger for ' + this.sObjectName);
    }

    private void executeBeforeInsert(){

        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof BeforeInsert) && isReExecutable(actioner)){

                    execute((BeforeInsert)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof BeforeInsert) && !skipActioner(actioner)){

                    execute((BeforeInsert)actioner);
                }
            }
        }
    }

    
    private void executeBeforeUpdate(){

        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof BeforeUpdate) && isReExecutable(actioner)){

                    execute((BeforeUpdate)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof BeforeUpdate) && !skipActioner(actioner)){

                    execute((BeforeUpdate)actioner);
                }
            }
        }
    }

    private void executeBeforeDelete(){

        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof BeforeDelete) && isReExecutable(actioner)){

                    execute((BeforeDelete)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof BeforeDelete) && !skipActioner(actioner)){

                    execute((BeforeDelete)actioner);
                }
            }
        }
    }
    
    private void executeAfterInsert(){

        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterInsert) && isReExecutable(actioner)){

                    execute((AfterInsert)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterInsert) && !skipActioner(actioner)){

                    execute((AfterInsert)actioner);
                }
            }
        }
    }
  
    private void executeAfterUpdate(){
        
        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterUpdate) && isReExecutable(actioner)){

                    execute((AfterUpdate)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterUpdate) && !skipActioner(actioner)){

                    execute((AfterUpdate)actioner);
                }
            }
        }
    }
    
    private void executeAfterDelete(){
        
        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterDelete) && isReExecutable(actioner)){

                    execute((AfterDelete)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterDelete) && !skipActioner(actioner)){

                    execute((AfterDelete)actioner);
                }
            }
        }
    }

    private void executeAfterUndelete(){
        
        if(alreadyRun()){

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterUndelete) && isReExecutable(actioner)){

                    execute((AfterUndelete)actioner);
                }
            }
        }
        else{

            markAlreadyRun();

            for(Actioner actioner : this.actioners){
                
                if((actioner instanceof AfterUndelete) && !skipActioner(actioner)){

                    execute((AfterUndelete)actioner);
                }
            }
        }
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

        return !(actioner instanceof RunOnce) && !skipActioner(actioner);
    }

    private Boolean alreadyRun(){

        return objectTriggerOperationsAlreadyRun.get(this.sObjectName)?.contains(Trigger.operationType) == true;
    }

    private void markAlreadyRun(){

        Set<TriggerOperation> triggerOperationsAlreadyRun = objectTriggerOperationsAlreadyRun.get(this.sObjectName);

        if(triggerOperationsAlreadyRun == null){

            triggerOperationsAlreadyRun = new Set<TriggerOperation>();

            objectTriggerOperationsAlreadyRun.put(this.sObjectName, triggerOperationsAlreadyRun);
        }

        triggerOperationsAlreadyRun.add(Trigger.operationType);
    }

    private Boolean skipActioner(Actioner actioner){

        return this.allowSkipTiger 
            && !(actioner instanceof NonSkipable) 
            && (this.userHasPermissionToSkipTigerActioners() || userHasPermissionToSkipActioner(actioner));
    }

    private Boolean userHasPermissionToSkipTigerActioners(){

        return FeatureManagement.checkPermission('SKIP_TIGER') 
            || FeatureManagement.checkPermission('SKIP_TIGER_' + this.sObjectName);
    }

    private Boolean userHasPermissionToSkipActioner(Actioner actioner){

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
