// SC für das Spiel "Schere, Stein, Papier" als Ethereum DApp

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Factory {

    address public owner;
    SchereSteinPapier[] public spiel;

    constructor() {
        owner = payable(msg.sender);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }


    function erzeugeSpiel() external payable {
        SchereSteinPapier schereSteinPapier = new SchereSteinPapier(payable(owner));
        spiel.push(schereSteinPapier);
    }

    function ETHabheben() public {
        require (msg.sender == owner, "Nur der Smart Contract owner/Betreiber ist berechtigt!");
        //require (status == Status.Beginn, "Es wird gerade gespielt!");
        payable(owner).transfer(address(this).balance);

    }

    receive() external payable{

    }


}

contract SchereSteinPapier {
    
    // speichern des Smart Contract owners/Betreibers
    //address public owner;

    // speichern der Spieler-Addressen
    address [2] public Spieler;

    // speichern der Adresse des Factory-Contracts
    address factory;

    // speichern des Spieleinsatzes
    uint public Einsatz;

    // speichern des verschlüsselten Spiel-Zugs
    bytes32[2] public VerschluesselterZug;
 
    // speichern des entschlüsselten Spiel-Zugs
    // 0: initial
    // 1: Schere
    // 2: Stein
    // 3: Papier
    uint[2] public Zug;

    // Spiel Status
    enum Status {Beginn, Wahl, Entscheidung, Auszahlung}
    Status status;

    // Timer
    uint public start;
    uint public stop;
    uint public start1;
    uint public stop1 = 100000000000000000000;
    uint public jetzt;

    // event für Einsatz
    event EinsatzIst (uint Einsatz);

    // event für Gewinner
    event GewinnerIst (address Gewinner);

    // Modifier zum Prüfen ob es sich um einen Spieler handelt
    modifier IstSpieler() {
        require (msg.sender == Spieler[0] || msg.sender == Spieler[1], "Du bist kein Spieler der aktieven Runde!");
        _;
    }

    // Konstruktor legt owner fest und initialisiert Variablen
    constructor(address _factory) {
        //owner = payable(msg.sender);
        factory = _factory;
        initialisieren();
    }

    // Funktion zum initialisieren des Spiels
    function initialisieren() private {
        Spieler[0] = payable(address(0));
        Spieler[1] = payable(address(0));
        VerschluesselterZug[0] = 0;
        VerschluesselterZug[1] = 0;
        Zug[0] = 0;
        Zug[1] = 0;
        status = Status.Beginn;
    }

    // Funktion zum Spiel-Beitritt
    function spielen() public payable {
         require (status == Status.Beginn, "Das Spiel hat bereits begonnen!");
         require (msg.value > 1000000000000000, "Du musst einen Einsatz (min. 0,001 ETH) setzen; der owner erhaelt 0,0001 ETH!");
         if (Spieler[0] == address(0)) {
             Einsatz = msg.value;
             emit EinsatzIst(Einsatz);
             Spieler[0] = payable(msg.sender);
         }
         else if (Spieler[1] == address(0)) {
             require (msg.sender != Spieler[0], "Du kannst nicht gegen dich selbst spielen!");
             require (msg.value == Einsatz, "Dein Spiel-Einsatz muss dem Vorgegebenen entsprechen!");
             Spieler[1] = payable(msg.sender);
             status = Status.Wahl;
             start = block.timestamp;
             stop = start + 30;
         }
    }

    // Funktion zum Wählen von Schere, Stein oder Papier
    function waehlen(bytes32 wahl) public IstSpieler {
        require (status == Status.Wahl, "Wahl kann noch nicht getroffen werden oder wurde bereits getroffen!");
        if (msg.sender == Spieler[0]) {
            VerschluesselterZug[0] = wahl;
        }
        else if (msg.sender == Spieler[1]) {
            VerschluesselterZug[1] = wahl;
        }
        if (VerschluesselterZug[0] != 0 && VerschluesselterZug[1] != 0) {
            status = Status.Entscheidung;
            start1 = block.timestamp;
            stop1 = start1 + 900;
        }
    }

    // Funktion deckt Wahl des Spielers auf
    function wahlentschluesseln(uint wahl, string memory schluessel) public IstSpieler {
        require (status == Status.Entscheidung, "Die Wahl kann noch nicht aufgedeckt werden!");
        bytes32 verschluesselt = keccak256(abi.encodePacked(wahl, schluessel)); //keccak256 takes a hex argument and not a string
        if (msg.sender == Spieler[0]) {
            if (verschluesselt == VerschluesselterZug[0]) {
                Zug[0] = wahl;
            }
        }
        else {
            if (verschluesselt == VerschluesselterZug[1]) {
                Zug[1] = wahl;
            }
        }
        if (Zug[0] != 0 && Zug[1] != 0) {
            status = Status.Auszahlung;
            entscheidung();
        }
    }

    // Funktion zur Entscheidungsfindung des Spiels
    function entscheidung() private {
        require (status == Status.Auszahlung);
        if (Zug[0] == 1) {
            if (Zug[1] == 1) {
                payable(Spieler[0]).transfer(Einsatz-100000000000000);
                payable(Spieler[1]).transfer(Einsatz-100000000000000);
            }
            if (Zug[1] == 2) {
                payable(Spieler[1]).transfer(2*Einsatz-200000000000000);
                emit GewinnerIst(Spieler[1]);
            }
            if (Zug[1] == 3) {
                payable(Spieler[0]).transfer(2*Einsatz-200000000000000);
                emit GewinnerIst(Spieler[0]);
            }
        }
        if (Zug[0] == 2) {
            if (Zug[1] == 1) {
                payable(Spieler[0]).transfer(2*Einsatz-200000000000000);
                emit GewinnerIst(Spieler[0]);
            }
            if (Zug[1] == 2) {
                payable(Spieler[0]).transfer(Einsatz-100000000000000);
                payable(Spieler[1]).transfer(Einsatz-100000000000000);
            }
            if (Zug[1] == 3) {
                payable(Spieler[1]).transfer(2*Einsatz-200000000000000);
                emit GewinnerIst(Spieler[1]);
            }
        }
        if (Zug[0] == 3) {
            if (Zug[1] == 1) {
                payable(Spieler[1]).transfer(2*Einsatz-200000000000000);
                emit GewinnerIst(Spieler[1]);
            }
            if (Zug[1] == 2) {
                payable(Spieler[0]).transfer(2*Einsatz-200000000000000);
                emit GewinnerIst(Spieler[0]);
            }
            if (Zug[1] == 3) {
                payable(Spieler[0]).transfer(Einsatz-100000000000000);
                payable(Spieler[1]).transfer(Einsatz-100000000000000);
            }
        }
        payable(factory).transfer(address(this).balance);
        initialisieren();
    }

    // Funktion zum Erstatten des Einsatzes
    function erstatten() public IstSpieler {
        jetzt = block.timestamp;
        require (status == Status.Wahl || status == Status.Entscheidung, "Du befindest dich im falschen Spiel-Status!");
        require (stop < jetzt || stop1 < jetzt, "Die Zeit ist noch nicht abgelaufen!");
        if (stop < jetzt) {
            if (VerschluesselterZug[0] == 0) {
                payable(Spieler[1]).transfer(2*Einsatz-200000000000000);
                initialisieren();
            }
            if (VerschluesselterZug[1] == 0) {
                payable(Spieler[0]).transfer(2*Einsatz-200000000000000);
                initialisieren();
            }
        }
        else if (stop1 < jetzt) {
            if (Zug[0] == 0) {
                payable(Spieler[1]).transfer(2*Einsatz-200000000000000);
                initialisieren();
            }
            if (Zug[1] == 0) {
                payable(Spieler[0]).transfer(2*Einsatz-200000000000000);
                initialisieren();
            }
        }
    }

    // Funktion um ETH-Balance abzuheben
    /*function ETHabheben() public  {
        require (msg.sender == owner, "Nur der Smart Contract owner/Betreiber ist berechtigt!");
        require (status == Status.Beginn, "Es wird gerade gespielt!");
        payable(owner).transfer(address(this).balance);
    }*/
}