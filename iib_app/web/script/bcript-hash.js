#!/usr/bin/env node

const bcrypt = require("bcryptjs");

// Get arguments from CLI
const args = process.argv.slice(2);

if (args.length < 2) {
    console.error("Usage: node bcrypt-hash.js <password> <saltRounds|salt>");
    process.exit(1);
}

const password = args[0];
const saltInput = args[1];

// Check if the input is a number (rounds) or a full salt string
if (!isNaN(saltInput)) {
    const saltRounds = parseInt(saltInput, 10);

    // Generate a salt with the given rounds
    bcrypt.genSalt(saltRounds, (err, salt) => {
        if (err) {
            console.error("Error generating salt:", err);
            process.exit(1);
        }
        hashPassword(password, salt);
    });
} else {
    // Use the provided salt directly
    hashPassword(password, saltInput);
}

// Function to hash the password
function hashPassword(password, salt) {
    bcrypt.hash(password, salt, (err, hash) => {
        if (err) {
            console.error("Error:", err);
            process.exit(1);
        }
        console.log("Bcrypt Hash:", hash);
    });
}
