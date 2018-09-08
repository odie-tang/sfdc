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
public abstract class OFieldType {
	
	public enum HtmlInputType {
		TEXT,PICKLIST,MULTIPICKLIST,CALENDER,POPUP
	}

	public abstract HtmlInputType defaultHtmlInputType();
	public abstract String[] getSupportedSearchingOperators();
	public abstract Object getFieldValue(String fieldValueInString);
	public abstract String getFieldValueInSoqlCondition(Object fieldValue);
	public abstract Schema.Displaytype getDisplayType();
	public abstract Boolean isFieldValueQuotedInSoql();
	
	

	public static OFieldType getInstance(String sObjectTypeName, String fieldName){
		
		return getInstance(UtilField.getFieldType(sObjectTypeName, fieldName));
	}
	
	public static OFieldType getInstance(Schema.DisplayType fieldDisplayType){
		
		return (OFieldType)Type.forName('O' + fieldDisplayType).newInstance();
	}
	
	public String[] getFieldValuesInSoqlCondition(Object[] fieldValues){
		
		String[] ret = new List<String>();
		
		for(Object fieldValue : fieldValues){
			ret.add(getFieldValueInSoqlCondition(fieldValue));
		}
		
		return ret;
	}
	
	public String getSoqlCondition(String fieldName, String searchingOperator, String fieldValueInString){
		
		String escapedFieldValueStr = String.escapeSingleQuotes(fieldValueInString);
		
		if(searchingOperator == 'equals') 
			return fieldName + ' = ' + escapedFieldValueStr;
		
		if(searchingOperator == 'not equal to') 
			return fieldName + ' <> ' + escapedFieldValueStr;
		
		if(searchingOperator == 'starts with') 
			return fieldName + ' like ' + escapedFieldValueStr + '%\'';
		
		if(searchingOperator == 'ends with') 
			return fieldName + ' like \'%' + escapedFieldValueStr;
		
		if(searchingOperator == 'contains') 
			return fieldName + ' like \'%' + escapedFieldValueStr + '%\'';
		
		if(searchingOperator == 'does not contain') 
			return '(not ' + fieldName + ' like \'%' + escapedFieldValueStr + '%\')';
		
		if(searchingOperator == 'less than') 
			return fieldName + ' < ' + escapedFieldValueStr;
		
		if(searchingOperator == 'greater than') 
			return fieldName + ' > ' + escapedFieldValueStr;
		
		if(searchingOperator == 'less or equal') 
			return fieldName + ' <= ' + escapedFieldValueStr;
		
		if(searchingOperator == 'greater or equal') 
			return fieldName + ' >= ' + escapedFieldValueStr;
		
		if(searchingOperator == 'includes') 
			return fieldName + ' in (' + String.join(conditionInValues(fieldValueInString),',') + ')';
		
		if(searchingOperator == 'excludes') 
			return fieldName + ' not in (' + String.join(conditionInValues(fieldValueInString),',') + ')';
		
		throw new ApplicationException('Searching Operator is not supported!');
	}

	private String[] conditionInValues(String fieldValueInString){
		
		String[] fieldValuesStr = fieldValueInString.split(',');
		
		String[] ret = new List<String>();
		
		for(String fieldValueStr : fieldValuesStr){
			
			if(!String.isBlank(fieldValueStr))
				ret.add(fieldValueStr);
		}
		
		return ret;
	}
	
	
	public class OAnyType extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			throw new ApplicationException();
		}
		public override String[] getSupportedSearchingOperators(){
			throw new ApplicationException();
		}
		public override Object getFieldValue(String fieldValueInString){
			throw new ApplicationException();
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			throw new ApplicationException();
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.AnyType;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			throw new ApplicationException();
		}
	}
	
	
	public class OBase64 extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			throw new ApplicationException();
		}
		public override String[] getSupportedSearchingOperators(){
			throw new ApplicationException();
		}
		public override Object getFieldValue(String fieldValueInString){
			return Blob.valueOf(fieldValueInString);		
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Base64;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	
	public class OBoolean extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Boolean.valueOf(fieldValueInString);	
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Boolean;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	
	public class OCombobox extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.PICKLIST;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'equals','not equal to','starts with','ends with','contains','does not contain','includes', 'excludes'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;		
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.escapeSingleQuotes(String.valueOf(fieldValue)) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Combobox;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	
	public class OCurrency extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'greater than','less than','less or equal','greater or equal', 'equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Decimal.valueOf(fieldValueInString);		
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Currency;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	public class ODataCategoryGroupReference extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			throw new ApplicationException();
		}
		public override String[] getSupportedSearchingOperators(){
			throw new ApplicationException();
		}
		public override Object getFieldValue(String fieldValueInString){
			throw new ApplicationException();
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			throw new ApplicationException();
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.DataCategoryGroupReference;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			throw new ApplicationException();
		}
	}
	
	
	public class ODate extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.CALENDER;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'equals','not equal to','less than','greater than','less or equal','greater or equal'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Date.valueOf(fieldValueInString);
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Date;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	public class ODateTime extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.CALENDER;
		}
		public override String[] getSupportedSearchingOperators(){
			throw new ApplicationException();
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Datetime.valueOf(fieldValueInString);
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.DateTime;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	
	public class ODouble extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'less than','greater than','less or equal','greater or equal', 'includes', 'excludes','equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Double.valueOf(fieldValueInString);
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Double;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	
	public class OEmail extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'equals','not equal to','starts with','ends with','contains','does not contain','includes', 'excludes'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Double;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	
	public class OEncryptedString extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			throw new ApplicationException();
		}
		public override String[] getSupportedSearchingOperators(){
			throw new ApplicationException();
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			throw new ApplicationException();
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.EncryptedString;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	
	public class OId extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.POPUP;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'includes', 'excludes','equals','not equal to','less than','greater than','less or equal','greater or equal'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Id.valueOf(fieldValueInString);
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.valueOf(fieldValue) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.ID;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	
	public class OInteger extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'less than','greater than','less or equal','greater or equal','includes', 'excludes','equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Integer.valueOf(fieldValueInString);
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Integer;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	public class OMultiPicklist extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.PICKLIST;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'includes', 'excludes','equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.escapeSingleQuotes(String.valueOf(fieldValue)) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.MultiPicklist;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	
	public class OPercent extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'includes', 'excludes','equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Double.valueOf(fieldValueInString)/100;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Percent;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	public class OPhone extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'equals','not equal to','starts with','ends with','contains','does not contain','less than','greater than','less or equal','greater or equal', 'includes', 'excludes'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.escapeSingleQuotes(String.valueOf(fieldValue)) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Phone;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	
	public class OPicklist extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'includes', 'excludes','equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.escapeSingleQuotes(String.valueOf(fieldValue)) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Picklist;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	
	
	public class OReference extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.POPUP;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'includes', 'excludes','equals','not equal to','less than','greater than','less or equal','greater or equal'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return Id.valueOf(fieldValueInString);
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.valueOf(fieldValue) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Reference;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	
	public class OString extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'equals','not equal to','starts with','ends with','contains','does not contain','less than','greater than','less or equal','greater or equal', 'includes', 'excludes'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.escapeSingleQuotes(String.valueOf(fieldValue)) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Phone;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	public class OTextArea extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'equals','not equal to','starts with','ends with','contains','does not contain'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.escapeSingleQuotes(String.valueOf(fieldValue)) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.TextArea;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
	
	public class OTime extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			throw new ApplicationException();
		}
		public override String[] getSupportedSearchingOperators(){
			throw new ApplicationException();
		}
		public override Object getFieldValue(String fieldValueInString){
			throw new ApplicationException();
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			return String.valueOf(fieldValue);
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.Time;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return false;
		}
	}
	
	public class OUrl extends OFieldType{
		public override HtmlInputType defaultHtmlInputType(){
			return HtmlInputType.TEXT;
		}
		public override String[] getSupportedSearchingOperators(){
			return new String[]{'contains','does not contain','starts with','ends with','equals','not equal to'};
		}
		public override Object getFieldValue(String fieldValueInString){
			
			if(String.isBlank(fieldValueInString)) return null;
			
			return fieldValueInString;
		}
		public override String getFieldValueInSoqlCondition(Object fieldValue){
			
			if(fieldValue == null) return '\'\'';
			
			return '\'' + String.escapeSingleQuotes(String.valueOf(fieldValue)) + '\'';
		}
		public override Schema.Displaytype getDisplayType(){
			return Schema.Displaytype.URL;
		}
		public override Boolean isFieldValueQuotedInSoql(){
			return true;
		}
	}
}