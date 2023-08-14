/**
 * 
 * Source Code: 
 * https://github.com/odie-tang/sfdc/blob/master/force-app/main/default/classes/UtilCollection.cls
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
public with sharing class UtilCollection {

    public static String[] getStringFieldValues(SObject[] records, String fieldName) {

        String[] ret = new String[]{};

        String[] fieldNameSplits = fieldName.split('\\.');

        for(SObject record : records){

            String fieldValue = (String)getFieldValue(record, fieldNameSplits);

            if(fieldValue != null){

                ret.add(fieldValue);
            }
        }

        return ret;
    }

    public static Object getFieldValue(SObject record, String fieldName){

        return getFieldValue(record, fieldName.split('\\.'));
    }

    public static Object getFieldValue(SObject record, String[] fieldNameSplits){

        SObject sentinal = record;

        for(Integer i = 0; sentinal != null && i < fieldNameSplits.size() - 1; i++){

            sentinal = sentinal.getSObject(fieldNameSplits[i]);
        }

        return sentinal?.get(fieldNameSplits[fieldNameSplits.size() - 1]);
    }

    public static Map<String, SObject> getFieldToRecordMap(SObject[] records, String keyFieldName){

        Map<String, SObject> ret = new Map<String, SObject>();
        
        String[] fieldNameSplits = keyFieldName.split('\\.');

        for(SObject record : records){

            String fieldValue = (String)getFieldValue(record, fieldNameSplits);

            ret.put(fieldValue, record);
        }

        return ret;
    }

    public static Map<String, SObject[]> getFieldToRecordSMap(SObject[] records, String keyFieldName){

        Map<String, SObject[]> ret = new Map<String, SObject[]>();
        
        String[] fieldNameSplits = keyFieldName.split('\\.');

        for(SObject record : records){

            String fieldValue = (String)getFieldValue(record, fieldNameSplits);

            SObject[] mappedRecords = ret.get(fieldValue);

            if(mappedRecords == null){

                mappedRecords = new SObject[]{};
                ret.put(fieldValue, mappedRecords);
            }

            mappedRecords.add(record);
        }

        return ret;
    }
}