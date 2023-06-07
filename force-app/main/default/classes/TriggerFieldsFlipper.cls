/**
 * 
 * Copyright (c), odie.tang
 * 
 * Source Code: 
 * https://github.com/odie-tang/sfdc/blob/develop/base/force-app/main/default/classes/TriggerFieldsFlipper.cls
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
 * 
 * A generic APEX class that flips the checkbox fields to unchecked in the before triggers if they were checked, 
 * and tracks the history in "static" variables so that other APEX classes executed after this class can use the method "flipped" 
 * to check if a field for a particular record was flipped or not. 
 * 
 * This can be used when you have a checkbox field that is always meant to be "unchecked" by default, 
 * but if the record's creation or update sets the field to "checked", you would have some special handlings, 
 * such as firing off certain automations or integrations, or vice versa, NOT firing off certain automations or integrations. 
 * It allows flexibile controll over certain logic at the record level. 
 * 
 * One example - let's say your sObject is connected with other systems via a middleware, data changed in Salesforce needs to sync with 
 * the external systems, so you have a "future" method to fire off the data sync request to the middleware and the middileware syncs
 * the data with the other systems. 
 * However, when the middleware writes back the external ID or the integration status to the original record,
 * or if the data change was initiated in the external systems and the middleware is trying to sync the data to Salesforce,
 * both of the scenoarios should not trigger the data sync request that was designed to fire off when the data change is initiated within Salesforce.
 * So when the middleware makes the DML to Salesforce, it checks the flippableField,
 * and in the data sync Apex class, use "TriggerFieldsFlipper.flipped" to check and not fire off the integrations if it returns true.
 * 
 */
public with sharing class TriggerFieldsFlipper implements 
    Tiger.BeforeInsert, Tiger.AfterInsert, Tiger.BeforeUpdate{

    private static Map<Id, Set<String>> flippedMap = new Map<Id, Set<String>>();
    private static Map<SObject, Set<String>> beforeInsertFlippedMap = new Map<SObject, Set<String>>();

    private String[] flippableFieldNames;


    public TriggerFieldsFlipper(String[] flippableFieldNames){
        this.flippableFieldNames = flippableFieldNames;
    }

    public TriggerFieldsFlipper(String resetableFieldName){
        this.flippableFieldNames = new String[]{resetableFieldName};
    }

    public static Boolean flipped(SObject record, String fieldName){

        Set<String> flippedFieldNames = getFlippedFieldNames(record);

        return flippedFieldNames?.contains(fieldName) == true;
    }

    private static Set<String> getFlippedFieldNames(SObject record){

        if(record.Id == null){

            for(SObject beforeInsertRecord : beforeInsertFlippedMap.keySet()){

                if(beforeInsertRecord === record){

                    return beforeInsertFlippedMap.get(beforeInsertRecord);
                }
            }

            return null;
        }
        else{

            return flippedMap.get(record.Id);
        }
    }

    public Boolean inScopeBeforeInsert(SObject newRecord){

        Set<String> flippedFieldNames = new Set<String>();

		for(String fieldName : this.flippableFieldNames) {

			if(newRecord.get(fieldName) == true) {
				
                flippedFieldNames.add(fieldName);
			}
		}

        if(flippedFieldNames.isEmpty()){

            return false;
        }
        else{

            beforeInsertFlippedMap.put(newRecord, flippedFieldNames);

            return true;
        }
    }

    public void processBeforeInsert(SObject[] scope){

        resetFields(scope);
    }

    public Boolean inScopeAfterInsert(SObject newRecord){
        return true;
    }

    public void processAfterInsert(SObject[] scope){

        for(SObject insertRecord : beforeInsertFlippedMap.keySet()){

            flippedMap.put(insertRecord.Id, beforeInsertFlippedMap.get(insertRecord));
        }

        beforeInsertFlippedMap.clear();
    }

    public Boolean inScopeBeforeUpdate(SObject newRecord){

        Set<String> flippedFieldNames = new Set<String>();

		for(String fieldName : this.flippableFieldNames) {

			if(newRecord.get(fieldName) == true) {
				
                flippedFieldNames.add(fieldName);
			}
		}

        if(flippedFieldNames.isEmpty()){

            return false;
        }
        else{

            flippedMap.put(newRecord.Id, flippedFieldNames);

            return true;
        }
    }

    public void processBeforeUpdate(SObject[] scope){

        resetFields(scope);
    }

    private void resetFields(SObject[] scope){

        for(SObject newRecord : scope){

            for(String fieldName : this.flippableFieldNames) {

                newRecord.put(fieldName, false);
            }
        }
    }
}