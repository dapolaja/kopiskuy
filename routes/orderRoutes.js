const express = require('express');
const router = express.Router();

const orderController = require('../controllers/orderController');
const auth = require('../middleware/authMiddleware');
const verifyToken = require('../middleware/authMiddleware');

router.post('/cart', auth, orderController.addCart); 
router.get('/cart/:user_id', auth, orderController.getCart);
router.delete('/cart/:id', auth, orderController.deleteCart);
router.put('/cart/:id', verifyToken, orderController.updateQty);

router.post('/order', auth, orderController.checkout);
router.get('/history/:user_id', auth, orderController.history);
router.get('/order/:id', auth, orderController.detailOrder);
router.put('/order-status/:id', auth, orderController.updateStatus);
router.get('/recommendation', auth, orderController.recommendation);

module.exports = router;