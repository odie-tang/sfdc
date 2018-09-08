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
public class UtilMetadata {

public static Schema.DescribeSObjectResult getDescribeSObjectResult(String sObjectTypeName){

	return getSObjectType(sObjectTypeName).getDescribe();
}

public static Schema.DescribeSObjectResult getDescribeSObjectResult(SObject record){

	return record.getSObjectType().getDescribe();
}

public static Schema.DescribeSObjectResult getDescribeSObjectResult(SObject[] records){

	return records.getSObjectType().getDescribe();
}


public static String getKeyPrefix(String sObjectName){

	return getKeyPrefix(getDescribeSObjectResult(sObjectName));
}

public static String getKeyPrefix(Schema.DescribeSObjectResult describeSObjectResult){

	return describeSObjectResult.getKeyPrefix();
}

public static Schema.SObjectType getSObjectType(String sObjectTypeName){

	return Schema.getGlobalDescribe().get(sObjectTypeName);
}

public static String getLabel(String sObjectTypeName){

	return getDescribeSObjectResult(sObjectTypeName).getLabel();
}

public static String getLabelPlural(String sObjectTypeName){

	return getDescribeSObjectResult(sObjectTypeName).getLabelPlural();
}

public static String getSObjectTypeName(SObject record){

	return getDescribeSObjectResult(record).getName();
}

public static String getSObjectTypeName(SObject[] records){

	return getDescribeSObjectResult(records).getName();
}


private static Map<String, Map<String, Schema.ChildRelationship> > childRelationshipsMap = new Map<String, Map<String, Schema.ChildRelationship> >();

//Map<getRelationshipName, Schema.ChildRelationship>
public static Map<String, Schema.ChildRelationship> getChildRelationshipsMap(String sObjectTypeName){

	if(childRelationshipsMap.containsKey(sObjectTypeName))
		return childRelationshipsMap.get(sObjectTypeName);

	Schema.ChildRelationship[] relationships = getDescribeSObjectResult(sObjectTypeName).getChildRelationships();

	Map<String, Schema.ChildRelationship> ret = new Map<String, Schema.ChildRelationship>();

	for(Schema.ChildRelationship re : relationships) {
		ret.put(re.getRelationshipName(), re);
	}

	childRelationshipsMap.put(sObjectTypeName, ret);

	return ret;
}

public static String getChildRelationshipSObjectTypeName(String parentSObjectTypeName, String childRelationshipName){

	return getChildRelationshipsMap(parentSObjectTypeName).get(childRelationshipName).getChildSObject().getDescribe().getName();
}

public static Id getRecordTypeId(String sObjectTypeName, String recordTypeDeveloperName){

	return getDescribeSObjectResult(sObjectTypeName).getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
}
}