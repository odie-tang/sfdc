/*
*
* Test class for Tiger.cls
*
*/
@isTest
public with sharing class TigerTest {

    public static Boolean testing = false;

    @isTest
    public static void test(){

        TigerTest.testing = true;

        Integer totalNum = 50;

        Account[] accounts = new Account[]{};

        for(Integer i = 0; i < totalNum; i++){
            //replace the record creation accordingly
            Account account = new Account(Name = 'abc' + i, AccountNumber = 'abc'); 

            accounts.add(account);
        }

        insert accounts;

        for(Integer i = 0; i < totalNum; i++){

            accounts[i].AccountNumber += '_update';
        }

        update accounts;

        delete accounts;

        undelete accounts;
    }
}