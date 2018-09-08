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
public class UtilField {
   	
	public static Map<String, Schema.SObjectField> getFieldsMap(Schema.DescribeSObjectResult describeSObject){
    
    	return FieldIdentifier.getFieldsMap(describeSObject);
    }
    
    public static Map<String, Schema.SObjectField> getFieldsMap(String sObjectTypeName){
    
    	return getFieldsMap(UtilMetadata.getDescribeSObjectResult(sObjectTypeName));
    }
    
    
    public static Object getFieldValue(SObject sobj, String complexFieldName){
    	
    	String[] fieldNameSerials = complexFieldName.split('\\.');
    	
    	SObject currentSObject = sobj;
    	
    	for(Integer i = 0; i < fieldNameSerials.size() - 1; ++ i){
    		
    		currentSObject = currentSObject.getSObject(fieldNameSerials[i]);
    	}
    	
    	return currentSObject.get(fieldNameSerials[fieldNameSerials.size() - 1]);
    }
    
    public static String getSimpleFieldLabel(String sObjectTypeName, String fieldName){
    	
    	return new FieldIdentifier(sObjectTypeName, fieldName).getLastFieldLabel();
    }
    
    public static String getFieldLabel(String sObjectTypeName, String fieldName){
    	
    	return new FieldIdentifier(sObjectTypeName, fieldName).getLabel();
    }
    
    public static String getFieldLabel(String sObjectTypeName, String fieldName, Boolean showingSimpleLabel){
    	
    	if(showingSimpleLabel)
    		return getSimpleFieldLabel(sObjectTypeName, fieldName);
    	
    	return getFieldLabel(sObjectTypeName, fieldName);
    }
    
    public static String getFieldLabel(Schema.DescribeSObjectResult describeSObjectResult, String fieldName){
    	
    	return new FieldIdentifier(describeSObjectResult, fieldName).getLabel();
    }
    
    public static Schema.DisplayType getFieldType(String sObjectTypeName,String fieldName){
    	
    	return new FieldIdentifier(sObjectTypeName,fieldName).getType();
    }
    
    public static Schema.DisplayType getFieldType(SObject record,String fieldName){
    	
    	return getFieldType(UtilMetadata.getSObjectTypeName(record), fieldName);
    }
    
    public static Schema.DisplayType getFieldType(SObject[] records, String fieldName){
    	
    	
    	return getFieldType(UtilMetadata.getSObjectTypeName(records), fieldName);
    }
    
    public static Schema.DescribeFieldResult getDescribeFieldResult(String sObjectTypeName, String fieldName){
    	
    	return new FieldIdentifier(sObjectTypeName, fieldName).getLastDescribeFieldResult();
    }
    
    
    public static Schema.DescribeFieldResult getDescribeFieldResult(Schema.DescribeSObjectResult describeSObject, String fieldName){
    	
    	return new FieldIdentifier(describeSObject, fieldName).getLastDescribeFieldResult();
    }
        
    public static List<Schema.Picklistentry> getPicklist(Schema.DescribeSObjectResult describeSObject, String fieldName){
        
        return getDescribeFieldResult(describeSObject,fieldName).getPicklistValues();
    }
    
    public static List<Schema.Picklistentry> getPicklist(SObject obj,String fieldName){
        
        return getPicklist(obj.getSObjectType().getDescribe(), fieldName);
    }
    
    public static List<Schema.Picklistentry> getPicklist(String sObjectTypeName,String fieldName){
    	
    	return getPicklist(UtilMetadata.getDescribeSObjectResult(sObjectTypeName), fieldName);
    }
    
    
    public static List<SelectOption> addSelectOptions(List<SelectOption> initialOptions, String sObjectTypeName, String fieldName){
		
		for(Schema.Picklistentry entry : getPicklist(sObjectTypeName, fieldName)){
			if(entry.isActive()){
				initialOptions.add(
					new SelectOption(entry.getValue(), entry.getLabel()));
			}
		}
		
		return initialOptions;
    }
    
	//this method is designed for vfpage to use
    public static List<SelectOption> getSelectOptions(String sObjectTypeName, String fieldName){
		
		List<Schema.Picklistentry> picklistEntries = getPicklist(sObjectTypeName, fieldName);
		
		List<SelectOption> ret = new List<SelectOption>();
		
		ret.add(new SelectOption('', '---None---'));
		
		for(Schema.Picklistentry entry : picklistEntries){
			if(entry.isActive()){
				ret.add(
					new SelectOption(entry.getValue(), entry.getLabel()));
			}
		}
		
		return ret;
	}
	
	
	public static Component.Apex.SelectList getTagSelectList(String sObjectTypeName, String fieldName){
	 	
	 	Component.Apex.SelectList selectList = new Component.Apex.SelectList();
	
	 	Component.Apex.SelectOptions selectOptions = new Component.Apex.SelectOptions();
	 	selectOptions.value = getSelectOptions(sObjectTypeName, fieldName);
	 	selectList.childComponents.add(selectOptions);
	 	
	 	return selectList;
	}
    
    
    public static Boolean isNameField(String sObjectTypeName, String fieldName){
    	Schema.DescribeFieldResult fieldResult = getDescribeFieldResult(sObjectTypeName, fieldName);
    	return fieldResult.isNameField();
    }   
	
	
	public static Object getFieldValueFromString(String sObjectTypeName,String fieldName, String strValue){
		
		return OFieldType.getInstance(sObjectTypeName, fieldName).getFieldValue(strValue);
	}
	
}