import CPlaydate

/// Functions related to fetching and updating scoreboards.
///
/// > Warning: Scoreboard support is only available to games that are distributed via Panic in a Season or in Catalog.
public enum Scoreboards {
    // MARK: Public

    public typealias Score = PDScore
    public typealias ScoresList = PDScoresList
    public typealias BoardsList = PDBoardsList

    /// Adds a new score to the specified board. Invokes the given callback with the resulting rank for the given value.
    ///
    /// If Wi-Fi is not available, the outgoing value will be queued on device and sent to the server on a later attempt.
    /// In the case that it is added to the outgoing queue, the result will not specify a rank.
    public static func addScore(
        boardID: String,
        value: CUnsignedInt,
        callback: (@convention(c) (
            _ score: UnsafeMutablePointer<Score>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void)? = nil
    ) -> Int {
        Int(scoreboards.addScore.unsafelyUnwrapped(boardID, value, callback))
    }

    /// Gets the player’s personal best score. Invokes the given callback with the score.
    ///
    /// This will only operate on locally stored scores. In the event that there is no available high score for this player,
    /// the callback will be invoked with nil.
    public static func getPersonalBest(
        boardID: String,
        callback: (@convention(c) (
            _ score: UnsafeMutablePointer<Score>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void)? = nil
    ) -> Int {
        Int(scoreboards.getPersonalBest.unsafelyUnwrapped(boardID, callback))
    }

    /// Free a score struct that was provided to a callback.
    public static func freeScore(_ score: UnsafeMutablePointer<Score>) {
        scoreboards.freeScore.unsafelyUnwrapped(score)
    }

    /// Invokes the given callback with a list of the registered scoreboards. (Note that if you already know the string
    /// ID for the scoreboard you want to query, this call is unnecessary.)
    public static func getScoreboards(
        callback: @convention(c) (
            _ boards: UnsafeMutablePointer<BoardsList>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void
    ) -> Int {
        Int(scoreboards.getScoreboards.unsafelyUnwrapped(callback))
    }

    /// Free a list of scoreboards.
    public static func freeBoardsList(_ boardsList: UnsafeMutablePointer<BoardsList>) {
        scoreboards.freeBoardsList.unsafelyUnwrapped(boardsList)
    }

    public static func getScores(
        boardID: String,
        callback: @convention(c) (
            _ scores: UnsafeMutablePointer<ScoresList>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void
    ) -> Int {
        Int(scoreboards.getScores.unsafelyUnwrapped(boardID, callback))
    }

    /// Free a list of scores.
    public static func freeScoresList(_ scoresList: UnsafeMutablePointer<ScoresList>) {
        scoreboards.freeScoresList.unsafelyUnwrapped(scoresList)
    }

    // MARK: Private

    private static var scoreboards: playdate_scoreboards { Playdate.playdateAPI.scoreboards.pointee }
}
