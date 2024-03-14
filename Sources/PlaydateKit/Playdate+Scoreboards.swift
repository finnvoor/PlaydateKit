public import CPlaydate

public extension Playdate {
    enum Scoreboards {
        // MARK: Public

        public static func addScore(boardID: StaticString, value: UInt32, callback: AddScoreCallback) -> Int32 {
            scoreboards.addScore(boardID.utf8Start, value, callback)
        }

        public static func addScore(boardID: UnsafePointer<CChar>, value: UInt32, callback: AddScoreCallback) -> Int32 {
            scoreboards.addScore(boardID, value, callback)
        }

        public static func getPersonalBest(boardID: StaticString, callback: PersonalBestCallback) -> Int32 {
            scoreboards.getPersonalBest(boardID.utf8Start, callback)
        }

        public static func getPersonalBest(boardID: UnsafePointer<CChar>, callback: PersonalBestCallback) -> Int32 {
            scoreboards.getPersonalBest(boardID, callback)
        }

        public static func freeScore(_ score: UnsafeMutablePointer<PDScore>) {
            scoreboards.freeScore(score)
        }

        public static func getScoreboards(callback: BoardsListCallback) -> Int32 {
            scoreboards.getScoreboards(callback)
        }

        public static func freeBoardsList(_ boardsList: UnsafeMutablePointer<PDBoardsList>) {
            scoreboards.freeBoardsList(boardsList)
        }

        public static func getScores(boardID: StaticString, callback: ScoresCallback) -> Int32 {
            scoreboards.getScores(boardID.utf8Start, callback)
        }

        public static func getScores(boardID: UnsafePointer<CChar>, callback: ScoresCallback) -> Int32 {
            scoreboards.getScores(boardID, callback)
        }

        public static func freeScoresList(_ scoresList: UnsafeMutablePointer<PDScoresList>) {
            scoreboards.freeScoresList(scoresList)
        }

        // MARK: Private

        private static var scoreboards: playdate_scoreboards { playdateAPI.scoreboards.pointee }
    }
}
