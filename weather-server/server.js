const express = require('express');
const cors = require('cors');
const axios = require('axios');
const { MongoClient, ServerApiVersion } = require('mongodb');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

const TOMORROW_IO_API_URL = 'https://api.tomorrow.io/v4/timelines';
const TOMORROW_IO_API_KEY = 'BeBeliVdwyjOCFqrPzdx2RX4x6bGF0Pe';
const uri ="mongodb+srv://nvpatil:Namsangel@admin.0qmfg.mongodb.net/?retryWrites=true&w=majority&appName=admin";
const DATABASENAME = "fav";
const COLLECTION_NAME = "weather"
let database;

// Function to connect to MongoDB
async function connectToMongoDB() {
    try {
        const client = new MongoClient(uri);
        await client.connect();
        database = client.db(DATABASENAME);
        console.log("Connection successful to MongoDB");
    } catch (error) {
        console.error("Error connecting to MongoDB:", error);
    }
}

// Call the function to connect to MongoDB
connectToMongoDB();


// API to add an entry to the database
app.post('/add_entry', async (req, res) => {
    const { id, city, state, lat, lng } = req.body;

    // Validate that all required fields are present
    if ( !city || !state || lat === undefined || lng === undefined) {
        return res.status(400).json({ error: 'All fields (id, city, state, lat, lng) are required' });
    }

    try {
        // Insert the entry into the database with the specified fields
        const result = await database.collection(COLLECTION_NAME).insertOne({ id, city, state, lat, lng });
        res.status(201).json({ message: 'Entry added successfully', id: result.insertedId });
    } catch (error) {
        console.error("Error adding entry:", error);
        res.status(500).json({ error: 'Failed to add entry' });
    }
});



// API to retrieve all entries from the database
app.get('/get_entries', async (req, res) => {
    try {
        const entries = await database.collection(COLLECTION_NAME).find({}).toArray();
        res.json(entries);
    } catch (error) {
        console.error("Error retrieving entries:", error);
        res.status(500).json({ error: 'Failed to retrieve entries' });
    }
});


// API to delete an entry by custom 'id' field from the database
app.delete('/delete_entry', async (req, res) => {
    const { city, state } = req.query;

    if (!city && !state) {
        return res.status(400).json({ error: 'City or State is required for deletion' });
    }

    try {
        // Delete the document with the matching city or state field
        const result = await database.collection(COLLECTION_NAME).deleteOne({
            $or: [{ city }, { state }]
        });

        if (result.deletedCount === 1) {
            res.json({ message: 'Entry deleted successfully' });
        } else {
            res.status(404).json({ error: 'Entry not found' });
        }
    } catch (error) {
        console.error("Error deleting entry:", error);
        res.status(500).json({ error: 'Failed to delete entry' });
    }
});


// const client = new MongoClient(uri, {
//     serverApi: {
//         version: ServerApiVersion.v1,
//         strict: true,
//         deprecationErrors: true,
//     }
// });
// async function run() {
//     try {
//         // Connect the client to the server	(optional starting in v4.7)
//         await client.connect();
//         // Send a ping to confirm a successful connection
//         await client.db("fav").command({ ping: 1 });
//         console.log("Pinged your deployment. You successfully connected to MongoDB!");
//     } finally {
//         // Ensures that the client will close when you finish/error
//         await client.close();
//     }
// }
// run().catch(console.dir);
app.get('/get_weather', async (req, res) => {
    const { lat, lng } = req.query;

    if (!lat || !lng) {
        return res.status(400).json({ error: 'Latitude and longitude are required' });
    }

    try {
        const weatherParams = {
            location: `${lat},${lng}`,
            fields: [
                'temperature', 'temperatureApparent', 'temperatureMin', 'temperatureMax',
                'windSpeed', 'windDirection', 'humidity', 'pressureSeaLevel',
                'weatherCode', 'precipitationProbability', 'precipitationType',
                'sunriseTime', 'sunsetTime', 'visibility', 'moonPhase', 'cloudCover','uvIndex'
            ],
            units: 'imperial',
            timesteps: ['1d', '1h'],
            timezone: 'America/Los_Angeles',
            apikey: TOMORROW_IO_API_KEY
        };

        const response = await axios.get(TOMORROW_IO_API_URL, { params: weatherParams });
        res.json(response.data);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to fetch weather data' });
    }
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});