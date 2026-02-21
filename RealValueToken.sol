// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Εισαγωγή των αδιάρρηκτων προτύπων της OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Real Value Token ($RVT)
 * @dev Το επίσημο νόμισμα διακυβέρνησης και ανταμοιβής κοινωνικού αποτυπώματος (ESG).
 */
contract RealValueToken is ERC20, Ownable {

    // Ο Constructor ορίζει το όνομα και το σύμβολο του Token
    // Επίσης, ορίζει εσένα (msg.sender) ως τον επίσημο Ιδιοκτήτη (Owner)
    constructor() ERC20("Real Value Token", "RVT") Ownable(msg.sender) {
        
        // Δημιουργία (Mint) 1.000.000 tokens κατά το Deploy.
        // Το 10**decimals() προσθέτει τα 18 δεκαδικά ψηφία (όπως το ETH).
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    /**
     * @dev Λειτουργία για την επιβράβευση χρηστών με βάση το Social Impact Score τους.
     * Μόνο ο Ιδιοκτήτης (εσύ) μπορεί να καλέσει αυτή τη συνάρτηση (onlyOwner).
     */
    function rewardImpact(address user, uint256 amount) external onlyOwner {
        _mint(user, amount);
    }
}
