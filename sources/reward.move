module app_to_s::reward {
  use std::signer;
  use std::vector;
  use std::table::{Self, Table};
  use std::string::{Self, String};
  use aptos_framework::object::{Self, ObjectCore};
  use std::aptos_coin::{Self, AptosCoin};
  use std::coin::{Self, Coin};

   /// Address of the owner of this module
  const MODULE_OWNER: address = @app_to_s;

  struct Creator has key{
    owner: address,
    ai_table: Table<String, AI>,
  }

  struct AI has key, store {
    owner: address,
    id: String,
    collectingRewards: u64,
    rags: vector<RAG>,
  }

  struct RAG has store {
    hash: String,
  }

  struct Consumer has key {
    owner: address,
    free_trial_count: u64,
    balance: u64,
  }

  // ENTRY REGISTER USER
  entry fun register_user(caller: &signer, user_addr: address) {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    new_creator_and_transfer(caller, user_addr);
    new_consumer_and_transfer(caller, user_addr);
  }

  fun new_creator_and_transfer(caller: &signer, user_addr: address) {
    let caller_address = signer::address_of(caller);

    let constructor_ref = object::create_object(caller_address);
    let object_signer = object::generate_signer(&constructor_ref);

    move_to(&object_signer, Creator {
      owner: user_addr,
      ai_table: table::new<String, AI>()
    });
 
    // Transfer to user
    let object = object::object_from_constructor_ref<ObjectCore>(
      &constructor_ref
    );
    object::transfer(caller, object, user_addr);
  }

  fun new_consumer_and_transfer(caller: &signer, user_addr: address) {
    let caller_address = signer::address_of(caller);

    let constructor_ref = object::create_object(caller_address);
    let object_signer = object::generate_signer(&constructor_ref);
    
    move_to(&object_signer, Consumer {
      owner: user_addr,
      free_trial_count: 0,
      balance: 0,
    });
 
    // Transfer to user
    let object = object::object_from_constructor_ref<ObjectCore>(
      &constructor_ref
    );
    object::transfer(caller, object, user_addr);
  }
  #[view]
  public fun exists_creator_at(obj_addr: address): bool {
    exists<Creator>(obj_addr)
  }

  #[view]
  public fun exists_consumer_at(ob_addr: address): bool {
    exists<Consumer>(ob_addr)
  }
  
  // ENTRY REGISTER AI
  entry fun register_ai(caller: &signer, creator_addr: address, creator_obj_address: address, ai_id: String, rag_hash: String) acquires Creator {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let creator_obj = borrow_global_mut<Creator>(creator_obj_address);
    table::add<String, AI>(
      &mut creator_obj.ai_table, 
      ai_id, 
      AI {
        owner: creator_addr,
        id: ai_id,
        collectingRewards: 0,
        rags: vector<RAG>[RAG{hash: rag_hash}],
      }
    );
  }

  #[view]
  public fun contain_ai(creator_obj_addr: address, ai_id: String) :bool acquires Creator {
    let creator_obj = borrow_global<Creator>(creator_obj_addr);
    table::contains<String, AI>(&creator_obj.ai_table, ai_id)
  }

  // ENTRY STORE VECTOR DATA
  entry fun store_rag_hash_data(caller: &signer, creator_addr: address, creator_obj_addr: address, ai_id: String, rag_hash: String) acquires Creator {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let creator_obj = borrow_global_mut<Creator>(creator_obj_addr);
    let ai = table::borrow_mut<String, AI>(&mut creator_obj.ai_table, ai_id);
    vector::push_back(&mut ai.rags, RAG{hash: rag_hash});
  }

  // user call from FE 
  // ENTRY RECHARGE CONSUMER BALANCE
  entry fun recharge_consumer_balance(caller: &signer, consumer_obj_addr: address) acquires Consumer {
    let amount = 1000; // 0.00001000 APT

    let consumer_obj = borrow_global_mut<Consumer>(consumer_obj_addr);
    consumer_obj.balance = consumer_obj.balance + amount;

    let caller_address = signer::address_of(caller);
    coin::transfer<AptosCoin>(caller, @app_to_s, amount);
  }

  #[view]
  public fun get_consumer_balance(consumer_obj_addr: address) :u64 acquires Consumer {
    let consumer_obj = borrow_global<Consumer>(consumer_obj_addr);
    consumer_obj.balance
  }

  // ENTRY PAY FOR USAGE
  entry fun pay_for_usage(caller: &signer, creator_obj_addr: address, ai_id: String, consumer_obj_addr: address, amount: u64) acquires Creator, Consumer {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let creator_obj = borrow_global_mut<Creator>(creator_obj_addr);
    let ai = table::borrow_mut<String, AI>(&mut creator_obj.ai_table, ai_id);
    ai.collectingRewards = ai.collectingRewards + amount;

    let consumer_obj = borrow_global_mut<Consumer>(consumer_obj_addr);
    consumer_obj.balance = consumer_obj.balance - amount;
  }

  #[view]
  public fun get_ai_rewards(creator_obj_addr: address, ai_id: String) : u64 acquires Creator {
    let creator_obj = borrow_global<Creator>(creator_obj_addr);
    let ai = table::borrow<String, AI>(&creator_obj.ai_table, ai_id);
    ai.collectingRewards
  }

  // ENTRY CLAIM REWARDS
  entry fun claim_rewards_by_ai(caller: &signer, creator_addr: address, creator_obj_addr: address, ai_id: String) acquires Creator {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let creator_obj = borrow_global_mut<Creator>(creator_obj_addr);
    let ai = table::borrow_mut<String, AI>(&mut creator_obj.ai_table, ai_id);
    coin::transfer<AptosCoin>(caller, creator_addr, ai.collectingRewards);
    ai.collectingRewards = 0;

  }

  // ENTRY REQUEST FAUCET
  entry fun request_faucet(caller: &signer, consumer_obj_addr: address) acquires Consumer {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let consumer_obj = borrow_global_mut<Consumer>(consumer_obj_addr);
    assert!(consumer_obj.free_trial_count == 0, 10);
    consumer_obj.free_trial_count = 5;
  }

  #[view]
  public fun get_free_trial_count(consumer_obj_addr: address):u64 acquires Consumer {
    let consumer_obj = borrow_global_mut<Consumer>(consumer_obj_addr);
    consumer_obj.free_trial_count
  }

}