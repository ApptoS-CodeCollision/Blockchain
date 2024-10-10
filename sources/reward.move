module app_to_s::reward {
  use std::signer;
  use std::vector;
  use std::table::{Self, Table};
  use std::string::{Self, String};
  use aptos_framework::object::{Self, ObjectCore};
  use std::aptos_coin::{Self, AptosCoin};
  use std::coin::{Self, Coin};
  use app_to_s::coin::{Self}

   /// Address of the owner of this module
  const MODULE_OWNER: address = @app_to_s;

  struct Creator has key{
    owner: address,
    ai_table: Table<String, AI>,
  }

  struct AI has key, store {
    owner: address,
    id: String,
    collectingRewards: u64, // 우리 AS 코인으로 할 건데, 어떻게 타입을 설정해야 하지?
    rags: vector<RAG>,
  }

  struct RAG has store {
    prompt: String,
  }

  struct Consumer has key {
    owner: address,
    free_trial_count: u64,
    balance: u64,
  }
}