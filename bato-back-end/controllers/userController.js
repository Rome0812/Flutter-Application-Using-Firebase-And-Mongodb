const User = require("../models/User");
const bcrypt = require("bcryptjs"); // For password hashing
const jwt = require("jsonwebtoken"); // For generating tokens


const getUsers = async (req, res) => {
  try {
    const users = await User.find({}, "-password"); // Exclude the password field
    res.json({ users });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
const createUser = async (req, res) => {
  try {
    // Ensure the password is included in the request body.
    if (!req.body.password) {
      return res.status(400).json({ message: "Password is required" });
    }
    // Hash the password
    const hashedPassword = await bcrypt.hash(req.body.password, 10);
    // Create the user with the hashed password
    const user = await User.create({ ...req.body, password: hashedPassword });
    res.status(201).json(user);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
const updateUser = async (req, res) => {
  try {
    // Check if the password is being updated
    if (req.body.password) {
      // Hash the new password
      req.body.password = await bcrypt.hash(req.body.password, 10);
    }
    // Update the user with the new data
    const user = await User.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
    });
    res.json(user);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Update username only
const updateUsername = async (req, res) => {
  try {
    const { username } = req.body;
    const { id } = req.params;

    if (!username) {
      return res.status(400).json({ message: "Username is required" });
    }

    // Check if username already exists (excluding current user)
    const existingUser = await User.findOne({ 
      username, 
      _id: { $ne: id } 
    });
    
    if (existingUser) {
      return res.status(409).json({ message: "Username already in use" });
    }

    const user = await User.findByIdAndUpdate(
      id, 
      { username }, 
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ message: "Username updated successfully", user });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// Change password
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const { id } = req.params;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: "Current password and new password are required" });
    }

    // Find the user
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
      return res.status(401).json({ message: "Current password is incorrect" });
    }

    // Hash new password
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await User.findByIdAndUpdate(id, { password: hashedNewPassword });

    res.json({ message: "Password changed successfully" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteUser = async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: "User deleted successfully" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};
const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find the user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Check if the user is active
    if (!user.isActive) {
      return res
        .status(403)
        .json({ message: "Your account is inactive. Please contact support." });
    }

    // Compare the provided password with the hashed password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Generate a JWT token
    const token = jwt.sign(
      { id: user._id, email: user.email, type: user.type }, // payload
      process.env.JWT_SECRET, // secret key
      { expiresIn: "1h" } // options
    );

    // Exclude password before sending user data
    const { password: _, ...userWithoutPassword } = user.toObject();

    res.json({
      message: "Login successful",
      token,
      user: userWithoutPassword, // full user details
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


const signupUser = async (req, res) => {
  try {
    const {
      firstName,
      lastName,
      age,
      gender,
      contactNumber,
      email,
      username,
      address,
      password,
      type,
    } = req.body;

    // Validate required fields
    if (!firstName || !lastName || !email || !username || !password) {
      return res.status(400).json({ message: "Please fill in all required fields" });
    }

    // Check if email already exists
    const existingEmail = await User.findOne({ email });
    if (existingEmail) {
      return res.status(409).json({ message: "Email already in use" });
    }

    // Check if username already exists
    const existingUsername = await User.findOne({ username });
    if (existingUsername) {
      return res.status(409).json({ message: "Username already in use" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = await User.create({
      firstName,
      lastName,
      age,
      gender,
      contactNumber,
      email,
      username,
      address,
      password: hashedPassword,
      isActive: true,
      type: type || "admin", // default role
    });

    // Generate JWT
    const token = jwt.sign(
      { id: newUser._id, email: newUser.email, type: newUser.type },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    // Remove password from response
    const { password: pw, ...userWithoutPassword } = newUser.toObject();

    res.status(201).json({
      message: "Signup successful",
      user: userWithoutPassword,
      token,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


module.exports = { 
  getUsers, 
  createUser, 
  updateUser, 
  deleteUser, 
  loginUser, 
  signupUser,
  updateUsername,
  changePassword
};