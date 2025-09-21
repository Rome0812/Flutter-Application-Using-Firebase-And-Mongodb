require("dotenv").config();
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const jsonParser = bodyParser.json();
const connectDB = require("./config/db");
const userRoutes = require("./routes/userRoutes");
const articleRoutes = require("./routes/articleRoutes");

const app = express();

connectDB();

app.use(jsonParser);
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cors());

const cosOptions = {
  origin: "*",
  credentials: true,
  allowedHeaders: ["Content-Type", "Authorization, X-Requested-With"],
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  preflightContinue: false,
  optionsSuccessStatus: 204,
};

app.options(/.*/, cors(cosOptions));
app.use(cors(cosOptions));

app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With",
    "Content-Type",
    "Accept",
    "Authorization"
  );

  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, DELETE, OPTIONS"
  );
  next();
});

app.use("/api/users", userRoutes);
app.use("/api/articles", articleRoutes);

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: "Server Error" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
