/**
 * 
 * Blog: https://odietang.blogspot.com/2020/08/introduction-to-tiger.html
 * 
 * Source Code: 
 * https://github.com/odie-tang/sfdc/blob/develop/base/force-app/main/default/classes/UtilTrigger.cls
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
public class UtilTrigger {

	public static Boolean anyFieldChanged(SObject record, String[] fieldNames){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject oldRecord = Trigger.oldMap.get(record.Id);

		for(String fieldName : fieldNames) {

			if(newRecord.get(fieldName) != oldRecord.get(fieldName)) {
				return true;
			}
		}

		return false;
	}

	public static Boolean fieldChanged(SObject record, String fieldName){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject recordOld = Trigger.oldMap.get(record.Id);

		return newRecord.get(fieldName) != recordOld.get(fieldName);
	}

	public static Boolean fieldChangedFrom(SObject record, String fieldName, Object oldValue){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject oldRecord = Trigger.oldMap.get(record.Id);

		return oldRecord.get(fieldName) == oldValue && newRecord.get(fieldName) != oldValue;
	}

	public static Boolean fieldChangedTo(SObject record, String fieldName, Object newValue){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject oldRecord = Trigger.oldMap.get(record.Id);

		return oldRecord.get(fieldName) != newValue && newRecord.get(fieldName) == newValue;
	}

	public static Boolean fieldChanged(SObject record, String fieldName, Object oldValue, Object newValue){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject oldRecord = Trigger.oldMap.get(record.Id);

		return oldRecord.get(fieldName) == oldValue && newRecord.get(fieldName) == newValue;
	}

	public static Boolean fieldChangedTo(SObject record, String fieldName, Object[] newValues){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject oldRecord = Trigger.oldMap.get(record.Id);

		if(oldRecord.get(fieldName) != newRecord.get(fieldName)) {

			for(Object value : newValues) {

				if(newRecord.get(fieldName) == value) {
					return true;
				}
			}
		}

		return false;
	}

	public static Boolean fieldChangedFrom(SObject record, String fieldName, Object[] oldValues){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject oldRecord = Trigger.oldMap.get(record.Id);

		if(oldRecord.get(fieldName) != newRecord.get(fieldName)) {

			for(Object oldValue : oldValues) {

				if(oldRecord.get(fieldName) == oldValue) {
					return true;
				}
			}
		}

		return false;
	}

	public static Boolean fieldChanged(SObject record, String fieldName, Object oldValue, Object[] newValues){

		return fieldChanged(record, fieldName, new Object[] {oldValue}, newValues);
	}

	public static Boolean fieldChanged(SObject record, String fieldName, Object[] oldValues, Object[] newValues){

		SObject newRecord = Trigger.newMap.get(record.Id);

		SObject oldRecord = Trigger.oldMap.get(record.Id);

		if(oldRecord.get(fieldName) != newRecord.get(fieldName)) {

			for(Object oldValue : oldValues) {

				if(oldRecord.get(fieldName) == oldValue) {

					for(Object newValue : newValues) {

						if(newRecord.get(fieldName) == newValue) {
							return true;
						}
					}
				}
			}

		}

		return false;
	}

	public static String sObjectName(){

		SObject[] records = trigger.old == null ? trigger.new : trigger.old;

		return records.getSObjectType().getDescribe().getName();
	}
}