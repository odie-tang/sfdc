public class UtilSObject {

	public static SObject copyFieldValuess(SObject copyFrom, SObject copyTo, String[] fieldNames){

		System.assert (copyFrom.getSObjectType() == copyTo.getSObjectType());

		for(String fieldName : fieldNames) {

			copyTo.put(fieldName, copyFrom.get(fieldName));
		}

		return copyTo;
	}

}
