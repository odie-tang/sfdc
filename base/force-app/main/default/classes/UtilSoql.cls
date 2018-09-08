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
public class UtilSoql {
	
	public static String valuesInSoqlCondition(SObject[] records, String fieldName){
		
		if(records == null || records.size() == 0) return null;

		Object[] fieldValues = UtilCollection.getFieldValuesList(records, fieldName);
		
		String sObjectName = records.getSObjectType().getDescribe().getName();
		
		OFieldType ft = OFieldType.getInstance(sObjectName, fieldName);
		
		String[] fieldValuesInSoql = ft.getFieldValuesInSoqlCondition(fieldValues);

		return '(' + String.join(fieldValuesInSoql, ',') + ')';
	}
    

	public static List<String> smallValueFieldNames(String sObjectTypeName){
		
		Map<String, Schema.SObjectField> fieldsMap = UtilField.getFieldsMap(sObjectTypeName);
		
		List<String> allSmallFields = new List<String>();
		
		for(String fieldName : fieldsMap.keySet()){
			
			Schema.SObjectField field = fieldsMap.get(fieldName);
			
			Schema.DisplayType displayType = field.getDescribe().getType();
			
			if(displayType != Schema.DisplayType.TextArea){
				allSmallFields.add(fieldName);
			}
		}
		return allSmallFields;
	}

}