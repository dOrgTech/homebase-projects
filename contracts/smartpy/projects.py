import smartpy as sp

FA2 = sp.import_script_from_url("https://smartpy.io/dev/templates/FA2.py")

class HomebaseProject(sp.Contract):
    def __init__(self, _externalRequirementsDocLink, _requirementsDocHash):
        self.init(
            stage = "Open",
            author = sp.sender,
            client = sp.none,
            contractor = sp.none,
            arbiter = sp.none,
            externalRequirementsDocLink = _externalRequirementsDocLink,
            requirementsDocHash = _requirementsDocHash,
            acceptedTokens = sp.big_map(tkey=sp.TAddress, tvalue=sp.TNat),
            contributions = sp.big_map(tkey=sp.TAddress, tvalue=sp.TNat)
        )

    @sp.entry_point
    def setParties(self, contractor, arbiter):
        sp.verify(self.data.stage == "Open")
        self.data.contractor = contractor
        self.data.arbiter = arbiter
        self.data.stage = "Pending"

    @sp.entry_point
    def signContract(self):
        sp.verify(self.data.stage == "Pending")
        self.data.stage = "Ongoing"

    @sp.entry_point
    def acceptPaymentTokens(self, token_address):
        sp.verify(self.data.stage == "Ongoing")
        self.data.acceptedTokens[token_address] = 0

    @sp.entry_point
    def sendFundsToProject(self, params):
        sp.verify(self.data.stage == "Ongoing")
        sp.verify(self.data.acceptedTokens.contains(params.token_address))
        transfer = sp.record(
            from_ = sp.sender,
            to_ = sp.self_address,
            token_id = 0,
            amount = params.amount
        )
        sp.transfer(transfer, sp.mutez(0), params.token_address)

    @sp.entry_point
    def releaseFundsToContractor(self, params):
        sp.verify(self.data.stage == "Ongoing")
        sp.verify(sp.sender == self.data.client.open_some())
        transfer = sp.record(
            from_ = sp.self_address,
            to_ = self.data.contractor,
            token_id = 0,
            amount = params.amount
        )
        sp.transfer(transfer, sp.mutez(0), params.token_address)
        self.data.stage = "Closed"

    @sp.entry_point
    def withdrawSupport(self, params):
        sp.verify((self.data.stage == "Pending") | (self.data.stage == "Dispute"))
        transfer = sp.record(
            from_ = sp.self_address,
            to_ = sp.sender,
            token_id = 0,
            amount = params.amount
        )
        sp.transfer(transfer, sp.mutez(0), params.token_address)
        self.data.contributions[sp.sender] = self.data.contributions[sp.sender] - params.amount

    @sp.entry_point
    def initiateDispute(self):
        sp.verify(self.data.stage == "Ongoing")
        sp.verify((sp.sender == self.data.client.open_some()) | (sp.sender == self.data.contractor))
        self.data.stage = "Dispute"

    @sp.entry_point
    def arbitrate(self, params):
        sp.verify(self.data.stage == "Dispute")
        sp.verify(sp.sender == self.data.arbiter)
        transfer = sp.record(
            from_ = sp.self_address,
            to_ = self.data.contractor,
            token_id = 0,
            amount = params.award_to_contractor
        )
        sp.transfer(transfer, sp.mutez(0), params.token_address)
        self.data.stage = "Closed"
