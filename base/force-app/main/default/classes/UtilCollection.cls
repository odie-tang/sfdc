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
public class UtilCollection {
	
	public static Integer removeFromList(List<Object> objs, Object obj){
		
		Integer indexInList = indexInList(objs, obj);
		
		if(indexInList >= 0){
			objs.remove(indexInList);
		}
		
		return indexInList;
	}
	
	
	public static Integer indexInList(List<Object> objs, Object obj){
		
		if(objs == null) return -1;
		
		for(Integer i = 0; i < objs.size(); ++i){
			
			Object objOfList = objs[i];
			
			if(objOfList == null){
				if(obj == null) return i;
			}
			else{
				if(objOfList == obj) return i;
			}
		}
		
		return -1;
	}
	
	public static Boolean contains(List<Object> objs, Object obj){
		
		return indexInList(objs, obj) >= 0;
	}
	
	public static Map<Id,SObject[]> groupRecordsByReference(List<SObject> sobjects, String referenceFieldName){
		
		Map<Id,SObject[]> ret = new Map<Id,SObject[]>();
		
		for(SObject obj : sobjects){
			
			Id id = (Id)obj.get(referenceFieldName);
			
			if(!ret.containsKey(id))
				ret.put(id, new List<SObject>());
			
			ret.get(id).add(obj);
		}
		
		return ret;
	}

	
	/*
	public static Map<String, SObject> getRecordsMap(List<SObject> records, String fieldNameOfKey){
		
		Map<String, SObject> sObjectMap = new Map<String, SObject>();
		
		if(records == null) return sObjectMap;
		
		for(SObject record : records){
			
			String key = String.valueOf(record.get(fieldNameOfKey));
			
			sObjectMap.put(key, record);
		}
		
		return sObjectMap;
	}

	*/
	
	public static Map<String, Set<SObject>> groupRecords(Set<SObject> records, String fieldNameAsKey){
	
		return groupRecords(new List<SObject>(records), fieldNameAsKey);
	}
	
	
	
	public static Map<String, Set<SObject>> groupRecords(List<SObject> records, String fieldNameAsKey){
		
		Map<String, Set<SObject>> ret = new Map<String, Set<SObject>>();
		
		if(records == null) return ret;
		
		for(SObject record : records){
			
			String key = String.valueOf(record.get(fieldNameAsKey));
			
			if(!ret.containsKey(key))
				ret.put(key, new Set<SObject>());
				
			ret.get(key).add(record);
		}
		
		return ret;
	}
	
	public static Map<String, Map<String, Set<SObject>>> groupRecords(Map<String, Set<SObject>> groupedRecords, String fieldNameAsSecondLevelKey){
		
		Map<String, Map<String, Set<SObject>>> ret = new Map<String, Map<String, Set<SObject>>>();
		
		for(String firstLevelKey : groupedRecords.keySet()){
			
			Set<SObject> firstLevelSet = groupedRecords.get(firstLevelKey);
			
			Map<String, Set<SObject>> groupedRecordsAsValue = groupRecords(firstLevelSet, fieldNameAsSecondLevelKey);
			
			ret.put(firstLevelKey, groupedRecordsAsValue);
		}
		
		return ret;
	}
	
	
	
	
	public static Object[] getFieldValuesList(SObject[] records, String fieldName){
		
		Object[] fieldValues = new List<Object>();
		
		if(records != null){
			
			for(SObject record : records){
			
				fieldValues.add(record.get(fieldName));
			}
		}
		
		return fieldValues;
	}
	
	public static Id[] getIdsList(SObject[] records){
		
		Id[] ret = new List<Id>();
		
		if(records != null){
			for(SObject record : records){
				ret.add(record.Id);
			}
		}
		
		return ret;
	}
	
	public static Set<Object> getFieldValuesSet(SObject[] records, String fieldName){
		
		Set<Object> fieldValues = new Set<Object>();
		
		if(records != null){
			
			for(SObject record : records){
			
				fieldValues.add(record.get(fieldName));
			}
		}
		
		return fieldValues;
	}

}