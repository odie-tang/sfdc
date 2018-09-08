/*
* odie.tang
*/
global class Stack {
	
	private List<Object> elements = new List<Object>();
	
	global Object peek(){
		
		if(isEmpty()) throw new ApplicationException('Stack is empty!');

		return elements.get(size() - 1);
	}
	
	global Object pop(){
		
		if(isEmpty()) throw new ApplicationException('Stack is empty!');
		
		return elements.remove(size() - 1);
	}
	
	global void push(Object obj){
		
		elements.add(obj);
	}
	
	global Boolean isEmpty(){
		
		return size() == 0;
	}
	
	global Integer size(){
		
		return elements.size();
	}
}