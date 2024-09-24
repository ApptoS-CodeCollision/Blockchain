module app_to_s::reward {
  use std::signer;
  use std::string::{Self, String};
  use aptos_framework::object::{Self, ObjectCore};

  struct Creator has key {
    owner: address,
    ais: vector<AI>
  }

  struct AI has key, store {
    owner: address,
  }

  struct Consumer has key {
    owner: address,
    free_trial_count: u64
  }
  
  struct MyStruct1 has key {
    message: String,
  }
  
  struct MyStruct2 has key {
    message: String,
  }
 
  entry fun create_and_transfer(caller: &signer, destination: address) {
    // Create object
    let caller_address = signer::address_of(caller);
    let constructor_ref = object::create_object(caller_address);
    let object_signer = object::generate_signer(&constructor_ref);
    
    // Set up the object by creating 2 resources in it
    move_to(&object_signer, MyStruct1 {
      message: string::utf8(b"hello")
    });
    move_to(&object_signer, MyStruct2 {
      message: string::utf8(b"world")
    });
 
    // Transfer to destination
    let object = object::object_from_constructor_ref<ObjectCore>(
      &constructor_ref
    );
    object::transfer(caller, object, destination);
  }


}