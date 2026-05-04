const express = require('express');
const router = express.Router();

const productController = require('../controllers/productController');
const auth = require('../middleware/authMiddleware');
const admin = require('../middleware/adminMiddleware');
const upload = require('../middleware/upload');

router.get('/products', productController.index);
router.get('/products/:id', productController.show);
router.post('/products',auth,admin,upload.single('image'),productController.addProduct);
router.put('/products/:id', auth, admin, productController.update);
router.delete('/products/:id', auth, admin, productController.destroy);

module.exports = router;