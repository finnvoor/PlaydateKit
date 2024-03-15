public import CPlaydate

public extension Playdate {
    enum Scoreboards {
        // MARK: Public

        public typealias Score = PDScore
        public typealias ScoresList = PDScoresList
        public typealias BoardsList = PDBoardsList

        public static func addScore(
            boardID: StaticString,
            value: UInt32,
            callback: @convention(c) (_ score: UnsafeMutablePointer<Score>?, _ errorMessage: UnsafePointer<CChar>?) -> Void
        ) -> Int32 {
            scoreboards.addScore(boardID.utf8Start, value, callback)
        }

        public static func addScore(
            boardID: UnsafePointer<CChar>,
            value: UInt32,
            callback: @convention(c) (_ score: UnsafeMutablePointer<Score>?, _ errorMessage: UnsafePointer<CChar>?) -> Void
        ) -> Int32 {
            scoreboards.addScore(boardID, value, callback)
        }

        public static func getPersonalBest(
            boardID: StaticString,
            callback: @convention(c) (_ score: UnsafeMutablePointer<Score>?, _ errorMessage: UnsafePointer<CChar>?) -> Void
        ) -> Int32 {
            scoreboards.getPersonalBest(boardID.utf8Start, callback)
        }

        public static func getPersonalBest(
            boardID: UnsafePointer<CChar>,
            callback: @convention(c) (_ score: UnsafeMutablePointer<Score>?, _ errorMessage: UnsafePointer<CChar>?) -> Void
        ) -> Int32 {
            scoreboards.getPersonalBest(boardID, callback)
        }

        public static func freeScore(_ score: UnsafeMutablePointer<Score>) {
            scoreboards.freeScore(score)
        }

        public static func getScoreboards(
            callback: @convention(c) (_ boards: UnsafeMutablePointer<BoardsList>?, _ errorMessage: UnsafePointer<CChar>?) -> Void
        ) -> Int32 {
            scoreboards.getScoreboards(callback)
        }

        public static func freeBoardsList(_ boardsList: UnsafeMutablePointer<BoardsList>) {
            scoreboards.freeBoardsList(boardsList)
        }

        public static func getScores(
            boardID: StaticString,
            callback: @convention(c) (_ scores: UnsafeMutablePointer<ScoresList>?, _ errorMessage: UnsafePointer<CChar>?) -> Void
        ) -> Int32 {
            scoreboards.getScores(boardID.utf8Start, callback)
        }

        public static func getScores(
            boardID: UnsafePointer<CChar>,
            callback: @convention(c) (_ scores: UnsafeMutablePointer<ScoresList>?, _ errorMessage: UnsafePointer<CChar>?) -> Void
        ) -> Int32 {
            scoreboards.getScores(boardID, callback)
        }

        public static func freeScoresList(_ scoresList: UnsafeMutablePointer<ScoresList>) {
            scoreboards.freeScoresList(scoresList)
        }

        // MARK: Private

        private static var scoreboards: playdate_scoreboards { playdateAPI.scoreboards.pointee }
    }
}
