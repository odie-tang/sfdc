public class CacheManager {

    private static Map<Id, SObject> cache = new Map<Id, SObject>();

    public static Boolean isCached(SObject record){

        return cache.containsKey(record.Id);
    }

    public static Boolean isCached(Id id){
        return cache.containsKey(id);
    }

    public static SObject getCache(Id id){
        return cache.get(id);
    }

    public static void addToCache(SObject record){
        cache.put(record.Id, record);
    }

    public static void addToCache(SObject[] records){

        for(SObject record : records){

            cache.put(record.Id, record);
        }
    }

    public static Id[] uncachedIds(SObject[] records){

        Id[] ret = new Id[]{};

        for(SObject record : records){

            if(!isCached(record))
                ret.add(record.Id);
        }

        return ret;
    }
}
