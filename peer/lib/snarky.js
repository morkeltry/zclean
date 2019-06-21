'use strict'

// SNARKY
const snarky = (config) => {
  return {
    makeProof: async (currentRoot, secret) => {
      // cli call currentRoot, secret => proof
      const proof = 'this is a proof'
      return proof
    },

    generateProof: (blockPrecursor, potentialSecret, nullifier) => {
      // cli call snarky_cli TBD
      //   bp { secret, currentRoot, path }
      //   potentialSecret
      //   nullifer
      //      => Proof
      const proof = 'PROOF1:PROOF2:PROOF3'

      return proof
    },

    verifyProofs: async (proposedBlock) => {

      const {
        root,
        nullifier,
        cm,
        nfProof,
        cmProof,
        bitProof
      } = proposedBlock

      // cli snarky_cli call to verify the proof

      // TODO
      return true
    }
  }
}

module.exports = snarky
