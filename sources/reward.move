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
    totalCollectedRewards: u64,
    rags: vector<RAG>,
  }

  struct RAG has store {
    prompt: String,
  }

  struct Consumer has key {
    owner: address,
    free_trial_count: u64,
    // balance: u64,
  }

  // ENTRY REGISTER USER
  entry fun register_user(caller: &signer) {
    let caller_address = signer::address_of(caller);

    new_creator(caller);
    new_consumer(caller);
  }

  fun new_creator(caller: &signer) {
    let caller_address = signer::address_of(caller);

    move_to(caller, Creator {
      owner: caller_address,
      ai_table: table::new<String, AI>()
    });
  }

  fun new_consumer(caller: &signer) {
    let caller_address = signer::address_of(caller);
    move_to(caller, Consumer {
      owner: caller_address,
      free_trial_count: 0,
      // balance: 0,
    });
  }

  // ENTRY REGISTER AI
  entry fun register_ai(caller: &signer, creator_address: address, ai_id: String, prompt: String) acquires Creator {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let creator_obj = borrow_global_mut<Creator>(creator_address);
    table::add<String, AI>(
      &mut creator_obj.ai_table, 
      ai_id, 
      AI {
        owner: creator_address,
        id: ai_id,
        totalCollectedRewards: 0,
        rags: vector<RAG>[RAG{prompt: prompt}],
      }
    );
  }

  // ENTRY STORE PROMPT DATA
  entry fun store_rag_data(caller: &signer, creator_address: address, ai_id: String, prompt: String) acquires Creator {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let creator_obj = borrow_global_mut<Creator>(creator_address);
    let ai = table::borrow_mut<String, AI>(&mut creator_obj.ai_table, ai_id);
    vector::push_back(&mut ai.rags, RAG{prompt: prompt});
  }

  // ENTRY REQUEST FAUCET
  entry fun request_faucet(caller: &signer, consumer_addr: address) acquires Consumer {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let consumer_obj = borrow_global_mut<Consumer>(consumer_addr);
    assert!(consumer_obj.free_trial_count == 0, 10);
    consumer_obj.free_trial_count = 5;
  }
  
  // ENTRY USE FREE TRIAL
  entry fun use_free_trial(caller: &signer, consumer_address: address) acquires Consumer {
    let caller_address = signer::address_of(caller);
    assert!(caller_address == MODULE_OWNER, 0);

    let consumer_obj = borrow_global_mut<Consumer>(consumer_address);
    consumer_obj.free_trial_count = consumer_obj.free_trial_count - 1;
  }

  // ENTRY PAY FOR USAGE
  entry fun pay_for_chat(caller: &signer, creator_address: address, ai_id: String, amount: u64) acquires Creator{
    let caller_address = signer::address_of(caller);

    let creator_obj = borrow_global_mut<Creator>(creator_address);
    let ai = table::borrow_mut<String, AI>(&mut creator_obj.ai_table, ai_id);
    ai.totalCollectedRewards = ai.totalCollectedRewards + amount;

    coin::transfer<AptosCoin>(caller, creator_address, amount);
  }
}