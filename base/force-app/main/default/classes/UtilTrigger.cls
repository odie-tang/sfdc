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

public static Boolean fieldChanged(SObject record, String fieldName, Object oldValue, Object newValue){

	SObject newRecord = Trigger.newMap.get(record.Id);

	SObject oldRecord = Trigger.oldMap.get(record.Id);

	return oldRecord.get(fieldName) == oldValue && newRecord.get(fieldName) == newValue;
}

public static Boolean fieldChanged(SObject record, String fieldName, Object newValue){

	SObject newRecord = Trigger.newMap.get(record.Id);

	SObject oldRecord = Trigger.oldMap.get(record.Id);

	return oldRecord.get(fieldName) != newValue
	       && newRecord.get(fieldName) == newValue;
}

public static Boolean fieldChangedAmongNews(SObject record, String fieldName, Object[] newValues){

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

public static String sObjectName(){

	SObject[] records = trigger.old == null ? trigger.new : trigger.old;

	return records.getSObjectType().getDescribe().getName();
}
}