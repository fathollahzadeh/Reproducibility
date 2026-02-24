WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation, U.CreationDate
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.AcceptedAnswerId,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.PostTypeId, P.CreationDate, P.AcceptedAnswerId, P.ViewCount, P.Score
)


SELECT 
    U.UserId,
    U.Reputation,
    U.BadgeCount,
    U.UpVotes AS UserUpVotes,
    U.DownVotes AS UserDownVotes,
    U.TotalViews AS UserTotalViews,
    U.TotalScore AS UserTotalScore,
    P.PostId,
    P.PostTypeId,
    P.CreationDate AS PostCreationDate,
    P.ViewCount AS PostViewCount,
    P.Score AS PostScore,
    P.CommentCount AS PostCommentCount,
    P.UpVotes AS PostUpVotes,
    P.DownVotes AS PostDownVotes
FROM UserStats U
JOIN PostStats P ON U.UserId = P.AcceptedAnswerId
ORDER BY U.Reputation DESC, P.Score DESC
LIMIT 100;