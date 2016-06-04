# KeySharingToKeySplitting
When exchanging a cryptographic key between two parties, the cryptographic key is often exchanged in multiple components for security reasons. Every component is exchanged for a different person from the sender to a different person of the receiver. The advantages are that no person at the sender or at the receiver side knows the cleartext value of the cryptographic key. Furthermore, it requires that an adversary has to intercept all components before (s)he can know the cleartext value of the cryptographic key.

## Key Sharing versus Key Splitting
There are two ways in which a cryptographic key can be divided in components:
* When sharing a key in multiple components, every component has the same length as the initial key. All components have to be xor-ed with each other to obtain the initial key again. The biggest advantage of this method is security: since all components have the same length, an adversary who has obtained one component must still search the entire key space for the other component(s). If an AES-128 key is shared in two components, and an adversary has obtained one component, then (s)he is still missing an 128-bit component. Searching for this component using a brute-force method is not feasible with current available computing resources. An additional advantage is that the order in which the components are xor-ed with each other is not important.
* When splitting a key in multiple components, every component is a substring of the initial key. All components have to be concatenated in the correct order to obtain the initial key again. The disadvantage of this method is that if an adversary has obtained a component, then the key space to search for the other component(s) is reduced significantly. If an AES-128 key is splitted in two components, and an adversary has obtained one component, then (s)he is missing an 64-bit component. Searching for this component using a brute-force method is feasible with current available computing resources!

## About this tool
Even though the disadvantages of using key splitting are well known, it can happen that parties with legacy systems cannot input a cryptographic key that is exchanged using the key sharing method.
This tool allows to convert shared components into splitted components by reconstructing the initial key and then splitting it. By using this tool, parties with legacy systems can exchange components using the key sharing method, and the components can be converted in a secure environment at the party before entering the key in the legacy system.

## Running this tool
This tool has been developed in AutoIt, a Windows scripting language. More information about AutoIt can be found here: https://www.autoitscript.com/

The source code of the application is available in the src directory of this repository.

A Windows binary is also available in the bin directory of this repository. The binary should work on any version of Windows and can be executed on both 32-bit and 64-bit Windows operating systems. The binary does not have to be installed, it works as a stand-alone program.

* sha256  f41405ec25c620ca1747c0c9d634e4ded54d9bdf90874c6c5004ad925c46ebcb  bin/KeySharingToKeySplitting.exe
* sha1  3f1a17a8988635fc0848597c18b14d3fe09cf0c9  bin/KeySharingToKeySplitting.exe
* md5  f92706ea1d031c70aed27cf9882d3a2e  bin/KeySharingToKeySplitting.exe
