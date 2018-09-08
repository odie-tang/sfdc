/**
 * Copyright (c), odie.tang (guihuatang@hotmail.com)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
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
public class CascadeQuerier {

/**
* sample SOQL: 'select Id, Name, (select Name, (select Name from DealSplits where Name like \'%ABc\' and Stage=1 order by yyyy desc), (select Name from Invoices order by Name desc) from Opportunities) from Account limit 10';
* sample SOQL: 'select Id, Name, (select Id, Name,(select Id, CaseNumber from Cases) from Contacts) from Account';
*/
public SObject[] RootRecords {get; private set;}
public Map<Id, SObject> RootRecordsMap {get; private set;}
public Map<Id, Map<String, SObject[]> > RecordTree {get; private set;}
public SObjectSoqlMeta RootMeta {get; private set;}
public String Soql {get; private set;}


public CascadeQuerier(String soql){
	this.Soql = soql;
	parseSoql(soql, true);
	queryFromRoot();
}

/*
 * this constructer simply assigns the parameter to the RootRecords
 * in order to have a unified interface in some situations and avoid a SOQL query
 */
public CascadeQuerier(SObject[] records){
	this.RootRecords = records;
	this.RootRecordsMap = new Map<Id, SObject>(records);
}

private SObjectSoqlMeta parseSoql(String soql, Boolean isRoot){

	Pattern p = Pattern.compile('(?i)select(.*)from(.*?)(?:where(.*?))?(?:order by(.*?))?(?:limit(\\d*))?$');

	Matcher matcher = p.matcher(soql);

	if(!matcher.find())
		throw new ApplicationException('Not able to understand the child relationship query!');

	SObjectSoqlMeta ret = new SObjectSoqlMeta();

	String fieldsStr = parseChildMetas(ret, matcher.group(1));

	parseFields(ret, fieldsStr);

	if(isRoot) {
		ret.sObjectName = matcher.group(2);
		this.RootMeta = ret;
	}
	else{
		ret.relationshipName = matcher.group(2);
	}
	ret.whereStr = matcher.group(3);
	ret.orderStr = matcher.group(4);
	ret.lmt = matcher.group(5) == null ? null : Integer.valueOf(matcher.group(5));

	return ret;
}

private void parseFields(SObjectSoqlMeta soqlMeta, String selectStr){

	Pattern p = Pattern.compile('([\\w]+?)\\s*[,$]');

	Matcher matcher = p.matcher(selectStr);

	while(matcher.find()) {
		soqlMeta.fields.add(matcher.group(1));
	}
}

private String parseChildMetas(SObjectSoqlMeta soqlMeta, String selectStr){

	String ret = selectStr;

	while(true) {

		Integer subQueryStart = ret.indexOf('(');

		if(subQueryStart < 0) break;

		Integer subQueryEnd = getSubQueryEnd(ret, subQueryStart);

		String subQuery = ret.substring(subQueryStart, subQueryEnd);

		SObjectSoqlMeta childMeta = parseSoql(subQuery, false);

		soqlMeta.addChild(childMeta);

		ret = ret.left(subQueryStart) + ret.right(ret.length() - subQueryEnd);

	}

	return ret;
}


private Integer getSubQueryEnd(String selectStr, Integer start){

	Stack stack = new Stack();
	stack.push('(');

	Integer i = start;

	while(++i < selectStr.length()) {

		String s = selectStr.subString(i, i+1);

		if(s == '(') {
			stack.push('(');
		}
		if(s == ')') {

			stack.pop();

			if(stack.isEmpty()) break;
		}
	}

	if(i == selectStr.length())
		throw new ApplicationException('Not able to understand the child relationship query!');

	return i;
}

public SObject[] getChildren(SObject parent, String relationshipName){

	return getChildren(parent.Id, relationshipName);
}

public SObject[] getChildren(Id id, String relationshipName){

	if(RecordTree != null
	   && RecordTree.containsKey(Id)
	   && RecordTree.get(Id).containsKey(relationshipName))
		return RecordTree.get(Id).get(relationshipName);

	return new List<SObject>();
}

public void printMeta(){
	printMeta(this.RootMeta);
}

private void printMeta(SObjectSoqlMeta sobjectSoqlMeta){

	system.debug('sobjectSoqlMeta ' + sobjectSoqlMeta);

	for(SObjectSoqlMeta child : SObjectSoqlMeta.chidlMetas)
		printMeta(child);
}

//an example to traverse all the items in the record hierarchy
public void print(){

	system.debug('RecordTree ' + RecordTree);

	for(SObject rootRecord : RootRecords) {

		print(this.RootMeta, rootRecord);
	}
}

private void print(SObjectSoqlMeta meta, SObject record){

	for(SObjectSoqlMeta childMeta : meta.chidlMetas) {

		if(!RecordTree.containsKey(record.Id)) continue;

		if(!RecordTree.get(record.Id).containsKey(childMeta.relationshipName)) continue;

		for(SObject childRecord : RecordTree.get(record.Id).get(childMeta.relationshipName)) {

			print(childMeta, childRecord);
		}
	}
}

private void queryFromRoot(){

	this.RecordTree = new Map<Id, Map<String, SObject[]> >();

	this.RootRecords =  Database.query(RootMeta.getSoqlAsRoot());

	this.RootRecordsMap = new Map<Id, SObject>(this.RootRecords);

	Map<SObjectSoqlMeta,SObject[]> childRecordsMapForNextQuery = buildRecordTree(rootMeta, rootRecords);

	for(SObjectSoqlMeta childMeta : childRecordsMapForNextQuery.keySet()) {

		queryAndBuildRecordTree(childMeta, childRecordsMapForNextQuery.get(childMeta));

	}

}

private void queryAndBuildRecordTree(SObjectSoqlMeta meta, SObject[] records){

	if(records.isEmpty()) return;

	for(SObjectSoqlMeta childMeta : meta.chidlMetas) {

		String q = childMeta.getSoqlAsChildRelationship(records);

		SObject[] childRecords = Database.query(q);

		Map<SObjectSoqlMeta, SObject[]> childRecordsMapForNextQuery = buildRecordTree(childMeta, childRecords);

		for(SObjectSoqlMeta grandMeta : childRecordsMapForNextQuery.keySet()) {

			queryAndBuildRecordTree(grandMeta, childRecordsMapForNextQuery.get(grandMeta));
		}

	}
}

private Map<SObjectSoqlMeta, SObject[]> buildRecordTree(SObjectSoqlMeta meta, SObject[] records){

	Map<SObjectSoqlMeta,SObject[]> childRecordsMapForNextQuery = new Map<SObjectSoqlMeta,SObject[]>();

	for(SObjectSoqlMeta childMeta : meta.chidlMetas)
		childRecordsMapForNextQuery.put(childMeta, new SObject[] {});


	for(SObject record : records) {

		if(meta.parentFieldName != null) {

			Id parentId = (Id)record.get(meta.parentFieldName);

			SObject[] recordsInTree = getRecordsInTree(parentId, meta.relationshipName);

			if(meta.lmt != null && recordsInTree.size() >= meta.lmt) break;

			recordsInTree.add(record);
		}

		for(SObjectSoqlMeta childMeta : meta.chidlMetas) {

			SObject[] childRecordsFromDB = record.getSObjects(childMeta.relationshipName);

			SObject[] childRecordsInTree = getRecordsInTree(record.Id, childMeta.relationshipName);

			if(childRecordsFromDB != null) {

				childRecordsInTree.addAll(childRecordsFromDB);

				childRecordsMapForNextQuery.get(childMeta).addAll(childRecordsFromDB);

				system.debug(' childRecordsFromDB ' + childRecordsFromDB + ' ' + childRecordsInTree);
			}
		}
	}

	return childRecordsMapForNextQuery;
}


private SObject[] getRecordsInTree(Id parentId, String relationshipName){

	if(!recordTree.containsKey(parentId))
		recordTree.put(parentId, new Map<String, SObject[]>());

	if(!recordTree.get(parentId).containsKey(relationshipName))
		recordTree.get(parentId).put(relationshipName, new SObject[] {});

	return recordTree.get(parentId).get(relationshipName);
}



public class SObjectSoqlMeta {

private String relationshipName;
private String sObjectName;
private SObjectSoqlMeta parent;
private String parentFieldName;
private String[] fields = new String[] {};
private SObjectSoqlMeta[] chidlMetas = new SObjectSoqlMeta[] {};
private String whereStr;
private String orderStr;
private Integer lmt;

public override String toString(){

	return 'sObjectName : ' + sObjectName 
	+ '\n relationshipName ' + relationshipName
	+ '\n parentFieldName ' + parentFieldName
	+ '\n fields ' + fields
	+ '\n whereStr ' + whereStr
	+ '\n orderStr ' + orderStr
	+ '\n lmt ' + lmt;
}

private void addChild(SObjectSoqlMeta childMeta){

	this.chidlMetas.add(childMeta);

	childMeta.parent = this;
}

private String getShallowSoql(){

	//String ret = 'select ' + String.join(fields, ',') + ' from ' + relationshipName + ' ' + UtilString.toStringIfNullBlank(whereStr) + ' ' +  UtilString.toStringIfNullBlank(orderStr) + limitStr();

	String t = 'select {0} from {1} {2} {3} {4}';

	String ret = String.format( t,
	                            new String[] {
				String.join(fields, ',')
				, relationshipName
				, whereStr == null ? '' : ' where ' + whereStr
				, orderStr == null ? '' : ' oder by ' + orderStr
				, lmt == null ? '' : ' limit ' + lmt
			}
	                            );

	//system.debug('shallow soql : ' + ret);

	return ret;
}

private void fillObjectInfoForRelationships(){

	if(relationshipName != null) {
		this.sObjectName = childRelationship().getChildSObject().getDescribe().getName();
		this.parentFieldName = childRelationship().getField().getDescribe().getName();
	}

	for(SObjectSoqlMeta child : chidlMetas) {

		child.fillObjectInfoForRelationships();
	}
}

private Schema.ChildRelationship childRelationship(){

	Schema.ChildRelationship childRelationship = UtilMetadata.getChildRelationshipsMap(parent.sObjectName).get(relationshipName);

	if(childRelationship == null)
		throw new ApplicationException('There is no such child relationship:' + relationshipName + ' in object ' + parent.sObjectName);

	return childRelationship;
}



private String getSoqlAsRoot(){

	String ret = 'select ' + String.join(fields, ',');

	for(SObjectSoqlMeta child : chidlMetas) {

		ret += ', (' + child.getShallowSoql() + ')';
	}

	ret += ' from ' + sObjectName;

	if(whereStr != null) ret += ' where ' + whereStr;

	if(orderStr != null) ret += ' order by ' + orderStr;

	if(lmt != null) ret += ' limit ' + lmt;

	//system.debug('root soql : ' + ret);

	return ret;
}


private String getSoqlAsChildRelationship(SObject[] parentRecords){

	String ret = 'select ' + parentFieldName + ',' + String.join(fields, ',');

	for(SObjectSoqlMeta child : chidlMetas) {

		ret += ', (' + child.getShallowSoql() + ')';
	}

	//ret += ' from ' + sObjectName + ' where ' + parentFieldName + ' in ' + UtilSoql.valuesInSoqlCondition(parentRecords, 'Id');

	if(whereStr != null)
		ret += ' and ' + whereStr;

	if(orderStr != null)
		ret += ' order by ' + orderStr;

	system.debug('child soql : ' + ret);

	return ret;
}

}
}