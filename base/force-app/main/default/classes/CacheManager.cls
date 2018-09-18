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
public class CacheManager {
    private final static Map<String, String> SOBJECT_BASE_SOQL_MAP = new Map<String, String>();
    private final static Map<Id, SObject> CACHE = new Map<Id, SObject>();
    private final static Map<Id, Map<String, SObject[]>> RECORD_TREE = new Map<Id, Map<String, SObject[]>>();

    public static Boolean isCached(SObject record){

        return CACHE.containsKey(record.Id);
    }

    public static Boolean isCached(Id id){
        return CACHE.containsKey(id);
    }

    public static SObject getCache(Id id){
        return CACHE.get(id);
    }

    public static void addToCache(SObject record){
        CACHE.put(record.Id, record);
    }

    public static void addToCache(SObject[] records){

        for(SObject record : records){

            CACHE.put(record.Id, record);
        }
    }

    public static Id[] uncachedIds(Id[] ids){

        Id[] ret = new Id[]{};

        for(Id id : ids){

            if(!isCached(id))
                ret.add(Id);
        }

        return ret;
    }

    public static void regesterSObjectBaseSoql(String sObjectName, String baseCascadeSoql){

        SOBJECT_BASE_SOQL_MAP.put(sObjectName, baseCascadeSoql);
    }

    public static Id[] queryAndCacheForTrigger(){

        if(trigger.isInsert)
            throw new ApplicationException('You can not query addtional information from DB in an insert operation!');
        
        return queryAndCache(trigger.new);
    }

    public static Id[] queryAndCache(SObject[] records){

        String sObjectName = records.getSObjectType().getDescribe().getName();

        String baseCascadeSoql = SOBJECT_BASE_SOQL_MAP.get(sObjectName);

        if(baseCascadeSoql == null){
            throw new ApplicationException('The base SOQL for the object [' + sObjectName + '] is undefined!');
        }

        Id[] ids = UtilCollection.getIdsList(records);

        return queryAndCache(baseCascadeSoql, ids);
    }

    public static Id[] queryAndCache(Id id){

        String sObjectName = id.getSobjectType().getDescribe().getName();

        String baseCascadeSoql = SOBJECT_BASE_SOQL_MAP.get(sObjectName);

        return queryAndCache(baseCascadeSoql, id);
    }

    private static Id[] queryAndCache(String baseCascadeSoql, Id id){

        return queryAndCache(baseCascadeSoql, new Id[]{id});
    }

    private static Id[] queryAndCache(String baseCascadeSoql, Id[] ids){
        
        Id[] uncachedIds = uncachedIds(ids);

        if(uncachedIds.isEmpty()) return uncachedIds;

        String cascadeSoql = hasWhereClause(baseCascadeSoql) ? 
                            baseCascadeSoql  + ' and Id in ' + UtilSoql.valuesInSoqlCondition(uncachedIds)
                            : baseCascadeSoql  + ' where Id in ' + UtilSoql.valuesInSoqlCondition(uncachedIds);

        CascadeQuerier cq = new CascadeQuerier(cascadeSoql);

        CACHE.putAll(cq.RootRecordsMap);

        for(Id id : cq.RecordTree.keySet()){

            if(!RECORD_TREE.containsKey(id))
                RECORD_TREE.put(id, new Map<String, SObject[]>());
            
            RECORD_TREE.get(id).putAll(cq.RecordTree.get(id));
        }

        return uncachedIds;
    }

    private static Boolean hasWhereClause(String soql){

        Pattern p = Pattern.compile('.*from.+(where)?.*$');

        Matcher matcher = p.matcher(soql);

        if(matcher.find())
            return matcher.group(1) != null;
        
        return false;
    }

    public static SObject[] getChildRecords(Id id, String childRelationName){

        if(RECORD_TREE.containsKey(id) 
            && RECORD_TREE.get(id).containsKey(childRelationName))
            return RECORD_TREE.get(id).get(childRelationName);
        
        return new SObject[]{};
    }
}
