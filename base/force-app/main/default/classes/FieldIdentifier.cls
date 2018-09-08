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
 */

/*
 * Identify and cache the field's metadata even for relational fields such as Case.Contact.Account.Name
 */
public class FieldIdentifier {

/*
 * there is a limitation on the Limits.getFieldsDescribes() <100>, each time calling fields.getMap() will count against the limitation. Cache the fieldMap to prevent the limitations.
 */
private static final Map<String,Map<String, Schema.SObjectField> > sObjectFieldsMap = new Map<String,Map<String, Schema.SObjectField> >();


private Schema.DescribeSObjectResult describeSObject;
private String fieldName;


public FieldIdentifier(Schema.DescribeSObjectResult describeSObject, String fieldName){
	this.describeSObject = describeSObject;
	this.fieldName = fieldName;
	identify();
}

public FieldIdentifier(String sObjectTypeName, String fieldName){
	this.describeSObject = UtilMetadata.getDescribeSObjectResult(sObjectTypeName);
	this.fieldName = fieldName;
	identify();
}

public List<Schema.DescribeFieldResult> describeFields {
	get {
		if(describeFields == null)
			describeFields = new List<Schema.DescribeFieldResult>();
		return describeFields;
	}
	private set;
}

public List<Schema.DescribeSObjectResult> describeSObjects {
	get {
		if(describeSObjects == null)
			describeSObjects = new List<Schema.DescribeSObjectResult>();
		return describeSObjects;
	}
	private set;
}


public static Map<String, Schema.SObjectField> getFieldsMap(Schema.DescribeSObjectResult describeSObject){

	String sObjectTypeName = describeSObject.getName();

	if(!sObjectFieldsMap.containsKey(sObjectTypeName)) {
		sObjectFieldsMap.put(sObjectTypeName,describeSObject.fields.getMap());
	}

	return sObjectFieldsMap.get(sObjectTypeName);
}

public static Schema.DescribeFieldResult getDescribeFieldResult(Schema.DescribeSObjectResult describeSObject, String simpleFieldName){

	return getFieldsMap(describeSObject).get(simpleFieldName).getDescribe();
}



public String getLastFieldLabel(){

	return getLastDescribeFieldResult().getLabel();
}

public String getLabel(){

	String ret = null;

	for(Schema.DescribeFieldResult describeField : describeFields) {

		if(ret == null) {
			ret = describeField.getLabel();
		}
		else{
			ret += ':' + describeField.getLabel();
		}
	}

	return ret;
}

public Schema.DisplayType getType(){

	return getLastDescribeFieldResult().getType();
}

public Schema.DescribeFieldResult getLastDescribeFieldResult(){

	return describeFields[describeFields.size() - 1];
}

private void identify(){

	identify(describeSObject, fieldName.split('\\.'), 0);
}

private void identify(Schema.DescribeSObjectResult describeSObject, String[] fieldNameStrs, Integer i){

	describeSObjects.add(describeSObject);

	Schema.DescribeFieldResult describeField = getDescribeFieldResult(describeSObject, getFieldName(fieldNameStrs, i ));

	describeFields.add(describeField);

	if(i == fieldNameStrs.size() -1 ) return;

	Schema.DescribeSObjectresult referenceToDescribe = describeField.getReferenceTo()[0].getDescribe();

	identify(referenceToDescribe, fieldNameStrs, ++i);
}


private String getFieldName(String[] fieldNameStrs, Integer i){

	if(i == fieldNameStrs.size() -1 )
		return fieldNameStrs[i];

	String relationName = fieldNameStrs[i].trim();

	return getRelationalFieldName(relationName);
}


private String getRelationalFieldName(String relationName){

	// parent relationship like RecordTypeId, AccountId...
	if(!relationName.endsWith('__r')) {
		return relationName + 'Id';
	}

	return relationName.substring(0, relationName.length() - 1) + 'c';
}


}