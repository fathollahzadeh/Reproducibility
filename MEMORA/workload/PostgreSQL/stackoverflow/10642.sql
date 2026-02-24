WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.Tags
    FROM Posts P
),
TopPostStats AS (
    SELECT
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.FavoriteCount,
        PS.Tags,
        RANK() OVER (ORDER BY PS.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PS.ViewCount DESC) AS ViewRank
    FROM PostStats PS
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.TotalScore,
    US.UpVotes,
    US.DownVotes,
    TPS.Title AS TopScorePostTitle,
    TPS.Score AS TopScorePostScore,
    TPS.ViewCount AS TopViewedPostCount
FROM UserStats US
LEFT JOIN TopPostStats TPS ON US.TotalScore = TPS.Score
WHERE TPS.ScoreRank = 1 OR TPS.ViewRank = 1
ORDER BY US.TotalScore DESC, US.DownVotes ASC;