const mongoose = require ('mongoose');

const articleSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true},
    title: { type: String, required: true},
    content: { type: [String], required: true},
    isActive: { type: Boolean, default: true},
});

module.exports = mongoose.model('Article', articleSchema);