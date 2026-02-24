
WITH RecursiveUserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        COALESCE(P.FavoriteCount, 0) AS FavoriteCount,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS ViewRank,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.FavoriteCount,
        PS.CreationDate,
        U.DisplayName AS OwnerDisplayName
    FROM PostStatistics PS
    JOIN Users U ON PS.PostId = U.Id
    WHERE PS.ViewRank <= 10 OR PS.ScoreRank <= 10
),
RecentBadgers AS (
    SELECT 
        B.UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    JOIN Users U ON B.UserId = U.Id
    WHERE B.Date >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 MONTH'
    GROUP BY B.UserId, U.DisplayName
)
SELECT 
    PS.Title,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    RUV.TotalVotes,
    RUV.UpVotes,
    RUV.DownVotes,
    RB.BadgeCount,
    RB.BadgeNames
FROM TopPosts PS
LEFT JOIN RecursiveUserVotes RUV ON PS.OwnerDisplayName = RUV.DisplayName
LEFT JOIN RecentBadgers RB ON RB.UserId = RUV.UserId
ORDER BY PS.ViewCount DESC, RUV.TotalVotes DESC;
