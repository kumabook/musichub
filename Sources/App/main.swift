import PostgreSQLProvider
import LeafProvider
import Fluent
import Console

let config = try Config()
try config.addProvider(PostgreSQLProvider.Provider.self)
try config.addProvider(LeafProvider.Provider.self)

config.preparations.append(Owner.self)
config.preparations.append(Artist.self)
config.preparations.append(Record.self)
config.preparations.append(Genre.self)
config.preparations.append(Pivot<Genre, Record>.self)
config.preparations.append(Album.self)
config.preparations.append(Track.self)

let console: ConsoleProtocol = Terminal(arguments: CommandLine.arguments)
let commands: [Command] = [
    ImportReordsCommand(console: console),
    ImportTracksCommand(console: console)
]
let drop = try Droplet(config: config, commands: commands)

drop.get("version") { request in
    if let db = drop.database?.driver as? PostgreSQLDriver.Driver {
        let version = try db.raw("SELECT version()")
        return try JSON(node: version)
    } else {
        return "No db connection"
    }
}

var root: RouteBuilder = drop
let authEnabled = false
if authEnabled {
    root = drop.grouped([BasicAuthMiddleware()])
}
root.resource("records", RecordController())
root.resource("artists", ArtistController())
root.resource("owners" , OwnerController())
root.resource("genres" , GenreController())
root.resource("artists", ArtistController())
root.resource("albums" , AlbumController())
root.resource("tracks" , TrackController())
drop.get("/") { request in
    return Response(redirect: "/artists?has_prefix=a")
}
try drop.run()
