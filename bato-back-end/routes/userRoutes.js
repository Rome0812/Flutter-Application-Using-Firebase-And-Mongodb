const express = require('express');
 
const { 
  getUsers, 
  createUser, 
  updateUser, 
  deleteUser, 
  loginUser, 
  signupUser,
  updateUsername,
  changePassword
} = require('../controllers/userController');
 
const router = express.Router();
 
router.route('/').get(getUsers).post(createUser);
router.route('/:id').put(updateUser).delete(deleteUser);
router.post('/login', loginUser);
router.post('/register', signupUser);
router.put('/:id/username', updateUsername);
router.put('/:id/password', changePassword);
 
module.exports = router;