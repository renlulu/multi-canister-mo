import IC "./ic";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import H "mo:base/HashMap";
import Hash "mo:base/Hash";
import Debug "mo:base/Debug";
import Array "mo:base/Array";

shared(msg) actor class (init_total_signer : Nat, init_quorum_number : Nat, init_signers : [Principal]) = self {

    let eq: (Nat, Nat) -> Bool = func(x, y) { x == y };

    let eq2: (Principal, Principal) -> Bool = func(x, y) { x == y };

    type TransactionType = { #create_canister; #start_canister; #stop_canister; #delete_canister };

    public type Proposal = {
        proposal_type : TransactionType;
        canister_id : Principal;
        commited_signer : [Principal];
        vote_yes : [Principal];
        vote_no : [Principal];
    };

    var total_signer : Nat = init_total_signer;

    var quorum_number : Nat = init_quorum_number;

    var transactions : H.HashMap<Nat, (TransactionType, Principal)> = H.HashMap<Nat, (TransactionType, Principal)>(100, eq, Hash.hash);

    var transaction_index : Nat = 0;

    var signatures : H.HashMap<Nat, Nat> = H.HashMap<Nat, Nat>(100, eq, Hash.hash);

    var signers : [Principal] = init_signers;

    var proposals : [Proposal] = [];


    public func propose(cid : Principal, ptype : TransactionType) {
        let commited_signer : [Principal] = [msg.caller];
        let vyes : [Principal] = [msg.caller];
        let vno : [Principal] = [];
        let proposal : Proposal = {proposal_type = ptype; canister_id = cid; commited_signer = commited_signer; vote_yes = vyes; vote_no = vno};
        let res = Array.append<Proposal>(proposals, [proposal]);
    };

    public func vote_yes(proposal_id : Nat) {
        // todo tell if he voted already
        let res = Array.append<Principal>( proposals[proposal_id].vote_yes, [msg.caller]);
    };

    public func vote_no(proposal_id : Nat) {
        // todo tell if he voted already
        let res = Array.append<Principal>( proposals[proposal_id].vote_no, [msg.caller]);
    };

    public func sumbit(signer_index : Nat, transaction_type : TransactionType, arg: Principal) {
        if (signers[signer_index] != msg.caller) {
        } else {
            transactions.put(transaction_index, (transaction_type, arg));
            transaction_index := transaction_index + 1;
        }
    };

    public func sign(signer_index : Nat, transaction_id : Nat) {
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

    public func execute(transaction_id : Nat) : async IC.canister_id {
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