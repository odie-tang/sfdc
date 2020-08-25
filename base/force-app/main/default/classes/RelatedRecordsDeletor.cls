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
public with sharing class RelatedRecordsDeletor{
    
    private String[] childRelateshipNames;

    public RelatedRecordsDeletor(String childRelateshipName){

        this(new String[]{childRelateshipName});
    }

    public RelatedRecordsDeletor(String[] childRelateshipNames) {

        this.childRelateshipNames = childRelateshipNames;
    }

    public void deleteChildren(SObject[] parents){

        String soql = 'SELECT Id';

        for(String childRenaltionshipName : childRelateshipNames){

            soql += ', (SELECT Id FROM ' + childRenaltionshipName + ')';
        }

        soql += ' FROM ' + parents.getSObjectType().getDescribe().getName() + ' WHERE Id IN:parents';

        List<SObject> toBeDeleted = new List<SObject>();

        for(SObject parent : Database.query(soql)){

            for(String childRenaltionshipName : childRelateshipNames){

                SObject[] children = parent.getSObjects(childRenaltionshipName);

                if(children != null)
                    toBeDeleted.addAll(children);
            }
        }

        delete toBeDeleted;
    }
}