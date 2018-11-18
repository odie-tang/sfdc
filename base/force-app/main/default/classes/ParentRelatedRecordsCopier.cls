public abstract class ParentRelatedRecordsCopier {
    private SObject[] children;
    private String parentFieldName;
    public ParentRelatedRecordsCopier(SObject[] children, String parentFieldName) {
        this.children = children;
        this.parentFieldName = parentFieldName;
    }

    
    public ParentRelatedRecordsCopier(String parentFieldName) {
        this(trigger.new, parentFieldName);
    }

    public abstract SObject[] createNewRecord(SObject child, CascadeQuerier cq);

    public abstract String soqlParentWithRelatedRecords();

    public void copy(){

        Id[] parentIds = (Id[])UtilCollection.getFieldValuesList(children, parentFieldName);

        String soql = soqlParentWithRelatedRecords() + ' WHERE Id in ' + UtilSoql.valuesInSoqlCondition(values);

        CascadeQuerier cq = new CascadeQuerier(soql);

        SObject[] newRecords = new SObject[]{};

        for(SObject child : children){

            newRecords.add(createNewRecord(child, cq));
        }

        insert newRecords;
    }
}
