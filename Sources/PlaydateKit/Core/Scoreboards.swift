public import CPlaydate

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
        boardID: StaticString,
        value: CUnsignedInt,
        callback: (@convention(c) (
            _ score: UnsafeMutablePointer<Score>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void)? = nil
    ) -> CInt {
        scoreboards.addScore(boardID.utf8Start, value, callback)
    }

    /// Adds a new score to the specified board. Invokes the given callback with the resulting rank for the given value.
    ///
    /// If Wi-Fi is not available, the outgoing value will be queued on device and sent to the server on a later attempt.
    /// In the case that it is added to the outgoing queue, the result will not specify a rank.
    public static func addScore(
        boardID: UnsafePointer<CChar>,
        value: CUnsignedInt,
        callback: (@convention(c) (
            _ score: UnsafeMutablePointer<Score>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void)? = nil
    ) -> CInt {
        scoreboards.addScore.unsafelyUnwrapped(boardID, value, callback)
    }

    /// Gets the player’s personal best score. Invokes the given callback with the score.
    ///
    /// This will only operate on locally stored scores. In the event that there is no available high score for this player,
    /// the callback will be invoked with nil.
    public static func getPersonalBest(
        boardID: StaticString,
        callback: (@convention(c) (
            _ score: UnsafeMutablePointer<Score>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void)? = nil
    ) -> CInt {
        scoreboards.getPersonalBest(boardID.utf8Start, callback)
    }

    /// Gets the player’s personal best score. Invokes the given callback with the score.
    ///
    /// This will only operate on locally stored scores. In the event that there is no available high score for this player,
    /// the callback will be invoked with nil.
    public static func getPersonalBest(
        boardID: UnsafePointer<CChar>,
        callback: (@convention(c) (
            _ score: UnsafeMutablePointer<Score>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void)? = nil
    ) -> CInt {
        scoreboards.getPersonalBest.unsafelyUnwrapped(boardID, callback)
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
    ) -> CInt {
        scoreboards.getScoreboards.unsafelyUnwrapped(callback)
    }

    /// Free a list of scoreboards.
    public static func freeBoardsList(_ boardsList: UnsafeMutablePointer<BoardsList>) {
        scoreboards.freeBoardsList.unsafelyUnwrapped(boardsList)
    }

    /// Invokes the given callback with a list of the top scores on the given board. (Typically ten scores or fewer.)
    /// If the current player is not in the top scores, their highest score is given as the last result.
    public static func getScores(
        boardID: StaticString,
        callback: @convention(c) (
            _ scores: UnsafeMutablePointer<ScoresList>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void
    ) -> CInt {
        scoreboards.getScores(boardID.utf8Start, callback)
    }

    public static func getScores(
        boardID: UnsafePointer<CChar>,
        callback: @convention(c) (
            _ scores: UnsafeMutablePointer<ScoresList>?,
            _ errorMessage: UnsafePointer<CChar>?
        ) -> Void
    ) -> CInt {
        scoreboards.getScores.unsafelyUnwrapped(boardID, callback)
    }

    /// Free a list of scores.
    public static func freeScoresList(_ scoresList: UnsafeMutablePointer<ScoresList>) {
        scoreboards.freeScoresList.unsafelyUnwrapped(scoresList)
    }

    // MARK: Private

    private static var scoreboards: playdate_scoreboards { Playdate.playdateAPI.scoreboards.pointee }
}
