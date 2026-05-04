const db = require('../config/db');

exports.index = (req, res) => {
    db.query("SELECT * FROM products", (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
};

exports.show = (req, res) => {
    const id = req.params.id;

    db.query(
        "SELECT * FROM products WHERE id=?",
        [id],
        (err, result) => {
            if (err) return res.status(500).json(err);
            res.json(result[0]);
        }
    );
};

exports.addProduct = (req, res) => {
    const { name, price, stock, description } = req.body;

    const image = req.file ? req.file.filename : null;

    if (!name || !price) {
        return res.status(400).json({ message: "Data tidak lengkap" });
    }

    db.query(
        "INSERT INTO products (name, price, stock, image, description) VALUES (?, ?, ?, ?, ?)",
        [name, price, stock, image, description],
        (err, result) => {
            if (err) {
                console.log(err);
                return res.status(500).json({ message: "Gagal tambah produk" });
            }

            res.json({
                message: "Produk berhasil ditambahkan",
                data: { name, price, stock, image, description }
            });
        }
    );
};

exports.update = (req, res) => {
    const id = req.params.id;
    const { name, price, stock, description } = req.body;
    const image = req.file ? req.file.filename : null;

    let query;
    let values;

    if (image) {
        query = "UPDATE products SET name=?, price=?, stock=?, description=?, image=? WHERE id=?";
        values = [name, price, stock,  description, image, id];
    } else {
        query = "UPDATE products SET name=?, price=?, stock=?, description=? WHERE id=?";
        values = [name, price, stock, description, id];
    }

    db.query(query, values, (err) => {
        if (err) return res.status(500).json(err);

        res.json({ message: "Produk berhasil diupdate" });
    });
};

exports.destroy = (req, res) => {
    const id = req.params.id;

    db.query(
        "DELETE FROM products WHERE id=?",
        [id],
        (err, result) => {
            if (err) return res.status(500).json(err);

            res.json({
                message: "Produk berhasil dihapus"
            });
        }
    );
};