const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
    const { name, email, password } = req.body;

    const hash = await bcrypt.hash(password, 10);

    db.query(
        "INSERT INTO users (name,email,password) VALUES (?,?,?)",
        [name, email, hash],
        (err, result) => {
            if (err) return res.status(500).json(err);

            res.json({
                message: "Register berhasil"
            });
        }
    );
};

exports.login = (req, res) => {
    const { email, password } = req.body;
    db.query(
        "SELECT * FROM users WHERE email=?",
        [email],
        async (err, result) => {

            if (result.length === 0) {
                return res.status(401).json({
                    message: "User tidak ditemukan"
                });
            }
            const user = result[0];
            const isMatch = await bcrypt.compare(password, user.password);

            if (!isMatch) {
                return res.status(401).json({
                    message: "Password salah"
                });
            }

            const token = jwt.sign(
                { id: user.id, role: user.role },
                process.env.JWT_SECRET
            );

            res.json({
                message: "Login berhasil",
                token: token,
                user: {
                    id: user.id,
                    email: user.email,
                    role: user.role
                }
            });
        }
    );
};