WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.FavoriteCount > 0 THEN 1 ELSE 0 END) AS FavoritePostCount 
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.AnswerCount,
        P.CreationDate,
        COALESCE(P.ClosedDate, '1970-01-01') AS ClosedDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
),
VoteStats AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM Votes V
    GROUP BY V.PostId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.BadgeCount,
    US.UpvoteCount AS UserUpvotes,
    US.DownvoteCount AS UserDownvotes,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    PS.CreationDate,
    PS.ClosedDate,
    PS.OwnerUserId,
    PS.OwnerDisplayName,
    VS.UpvoteCount AS PostUpvotes,
    VS.DownvoteCount AS PostDownvotes
FROM UserStats US
JOIN PostStats PS ON PS.OwnerUserId = US.UserId
LEFT JOIN VoteStats VS ON PS.PostId = VS.PostId
ORDER BY US.UserId, PS.CreationDate DESC;