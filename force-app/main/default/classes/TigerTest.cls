/*
*
* Test class for Tiger.cls
*
*/
@isTest
public with sharing class TigerTest {
    @isTest
    public static void test(){

        Integer totalNum = 50;

        Account[] accounts = new Account[]{};

        for(Integer i = 0; i < totalNum; i++){
            //replace the record creation accordingly
            Account account = new Account(Name = 'abc' + i); 

            accounts.add(account);
        }

        insert accounts;

        for(Integer i = 0; i < totalNum; i++){

            accounts[i].Name += '_update';
        }

        update accounts;

        delete accounts;

        undelete accounts;
    }
}