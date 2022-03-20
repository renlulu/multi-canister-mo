import IC "./ic";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import H "mo:base/HashMap";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";

shared(msg) actor class () = self {

    let eq: (Nat, Nat) -> Bool = func(x, y) { x == y };

    let eq2: (Principal, Principal) -> Bool = func(x, y) { x == y };

    type TransactionType = { #create_canister; #start_canister; #stop_canister; #delete_canister };

    var total_signer : Nat = 5;

    var quorum_number : Nat = 3;

    var transactions : H.HashMap<Nat, (TransactionType, Principal)> = H.HashMap<Nat, (TransactionType, Principal)>(100, eq, Hash.hash);

    var transaction_index : Nat = 0;

    var signatures : H.HashMap<Nat, Nat> = H.HashMap<Nat, Nat>(100, eq, Hash.hash);

    var signers : [Principal] = [];

    func sumbit(signer_index : Nat, transaction_type : TransactionType, arg: Principal) {
        if (signers[signer_index] != msg.caller) {
        } else {
            transactions.put(transaction_index, (transaction_type, arg));
            transaction_index := transaction_index + 1;
        }
    };

    func sign(signer_index : Nat, transaction_id : Nat) {
        if (signers[signer_index] != msg.caller) {
        } else {
            let signed_number = signatures.get(transaction_id);
            switch (signed_number) {
                case (null) {
                    signatures.put(transaction_id, 1)
                };

                case (?number) {
                    signatures.put(transaction_id, number + 1)
                };
            }
        }
    };

    func execute(transaction_id : Nat) : async IC.canister_id {
        let signed_number = signatures.get(transaction_id);
        switch (signed_number) {
          case (null) {
              Debug.trap("")
          };
          case (?number) {
              if (number > quorum_number) {
                let type_param_opt = transactions.get(transaction_id);
                switch (type_param_opt) {
                    case (null) {
                        Debug.trap("")
                    };
                    case (?type_param) {
                        let transaction_type = type_param.0;
                        let arg = type_param.1;
                        switch (transaction_type) {
                            case (#create_canister) {
                                await create_canister_func();
                            };
                            case (#start_canister) {
                                await start_canister_func(arg);
                            };
                            case (#stop_canister) {
                                await stop_canister_func(arg);
                            };
                            case (#delete_canister) {
                                await delete_canister_func(arg);
                            };
                        }
                    }
                }
              } else {
                  Debug.trap("")
              }
          };
        }
    };


    func create_canister_func() : async IC.canister_id {
        let settings = {
            freezing_threshold = null;
            controllers = ?[Principal.fromActor(self)];
            memory_allocation = null;
            compute_allocation = null;
        };

        let ic : IC.Self = actor("aaaaa-aa");
        let result = await ic.create_canister({ settings = ?settings; });
        result.canister_id
    };

    func start_canister_func(id : Principal) : async IC.canister_id {
        let ic : IC.Self = actor("aaaaa-aa");
        let result = await ic.start_canister({ canister_id = id; });
        id
    };

    func stop_canister_func(id : Principal) : async IC.canister_id {
        let ic : IC.Self = actor("aaaaa-aa");
        let result = await ic.stop_canister({ canister_id = id; });
        id
    };

    func delete_canister_func(id : Principal) : async IC.canister_id {
        let ic : IC.Self = actor("aaaaa-aa");
        let result = await ic.delete_canister({ canister_id = id; });
        id
    };
}