WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.OwnerUserId, P.Title, P.Score, P.ViewCount
    ORDER BY P.Score DESC, P.ViewCount DESC
    LIMIT 10
),
PostContributions AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        COUNT(PH.Id) AS EditCount
    FROM PostHistory PH
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY PH.PostId, PH.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    US.TotalBounty,
    US.TotalUpVotes,
    US.TotalDownVotes,
    PP.Title AS PopularPostTitle,
    PP.Score AS PostScore,
    PP.ViewCount AS PostViewCount,
    PC.EditCount AS UserEditCount
FROM Users U
JOIN UserScores US ON U.Id = US.UserId
JOIN PopularPosts PP ON U.Id = PP.OwnerUserId
LEFT JOIN PostContributions PC ON PP.PostId = PC.PostId AND U.Id = PC.UserId
ORDER BY US.Reputation DESC, PP.Score DESC;