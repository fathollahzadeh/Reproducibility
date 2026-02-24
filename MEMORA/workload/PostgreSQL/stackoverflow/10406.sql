WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCreated,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCreated
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
VotingSummary AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VotesCount,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY V.UserId
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    PS.OwnerReputation,
    UA.PostsCreated,
    UA.QuestionsCreated,
    UA.AnswersCreated,
    VS.VotesCount,
    VS.UpVotes,
    VS.DownVotes
FROM PostStatistics PS
LEFT JOIN UserActivity UA ON PS.OwnerDisplayName = UA.DisplayName
LEFT JOIN VotingSummary VS ON UA.UserId = VS.UserId
ORDER BY PS.CreationDate DESC;