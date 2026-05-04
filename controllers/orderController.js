const db = require('../config/db');

exports.addCart = (req, res) => {
    const user_id = req.user.id;
    const { product_id, qty } = req.body;
    db.query(
        "INSERT INTO carts (user_id,product_id,qty) VALUES (?,?,?)",
        [user_id, product_id, qty],
        (err, result) => {
            if (err) return res.status(500).json(err);

            res.json({
                message: "Masuk keranjang"
            });
        }
    );
};

exports.getCart = (req, res) => {
    const user_id = req.params.user_id;
    db.query(`
        SELECT carts.id, products.name, products.price, carts.qty
        FROM carts
        JOIN products ON carts.product_id = products.id
        WHERE carts.user_id=?
    `, [user_id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
};

exports.deleteCart = (req, res) => {
    const id = req.params.id;

    db.query(
        "DELETE FROM carts WHERE id=?",
        [id],
        (err, result) => {
            res.json({
                message: "Cart dihapus"
            });
        }
    );
};

exports.checkout = (req, res) => {
    const user_id = req.user.id;

    db.query(`
        SELECT carts.*, products.price, products.stock
        FROM carts
        JOIN products ON carts.product_id = products.id
        WHERE carts.user_id=?
    `, [user_id], (err, carts) => {

        if (carts.length == 0) {
            return res.json({
                message: "Cart kosong"
            });
        }
        let total = 0;
        for (let item of carts) {

            if (item.qty > item.stock) {
                return res.json({
                    message: `${item.product_id} stock tidak cukup`
                });
            }
            total += item.price * item.qty;
        }
        db.query(
            "INSERT INTO orders (user_id,total) VALUES (?,?)",
            [user_id, total],
            (err, result) => {
                const orderId = result.insertId;
                carts.forEach(item => {
                    db.query(
                        "INSERT INTO order_items (order_id,product_id,qty,price) VALUES (?,?,?,?)",
                        [orderId, item.product_id, item.qty, item.price]
                    );
                    db.query(
                        "UPDATE products SET stock = stock - ? WHERE id=?",
                        [item.qty, item.product_id]
                    );

                });

                db.query(
                    "DELETE FROM carts WHERE user_id=?",
                    [user_id]
                );

                res.json({
                    message: "Checkout berhasil",
                    total: total
                });

            }
        );

    });
};

exports.history = (req, res) => {
    const user_id = req.user.id;
    db.query(
        "SELECT * FROM orders WHERE user_id=?",
        [user_id],
        (err, result) => {
            res.json(result);
        }
    );
};

exports.detailOrder = (req, res) => {
    const id = req.params.id;

    db.query(`
        SELECT order_items.*, products.name
        FROM order_items
        JOIN products ON order_items.product_id = products.id
        WHERE order_id=?
    `, [id], (err, result) => {
        res.json(result);
    });
};

exports.updateStatus = (req, res) => {
    const id = req.params.id;
    const { status } = req.body;
    db.query(
        "UPDATE orders SET status=? WHERE id=?",
        [status, id],
        (err, result) => {
            res.json({
                message: "Status diupdate"
            });
        }
    );
};

exports.updateQty = (req, res) => {
    const { id } = req.params;
    const { qty } = req.body;
    db.query(
        "UPDATE carts SET qty=? WHERE id=?",
        [qty, id],
        (err, result) => {
            if (err) return res.status(500).json(err);

            res.json({
                message: "Qty diupdate"
            });
        }
    );
};

exports.recommendation = (req, res) => {
    const user_id = req.user.id;
    db.query(`
        SELECT products.*, COUNT(order_items.product_id) as total_beli
        FROM order_items
        JOIN products ON order_items.product_id = products.id
        JOIN orders ON order_items.order_id = orders.id
        WHERE orders.user_id = ?
        GROUP BY products.id
        ORDER BY total_beli DESC
        LIMIT 5
    `, [user_id], (err, result) => {
        if (err) return res.status(500).json(err);
        res.json(result);
    });
};