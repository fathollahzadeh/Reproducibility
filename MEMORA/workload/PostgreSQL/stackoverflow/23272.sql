
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        U.DisplayName, 
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PopularityRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount
),
PostVoteDetails AS (
    SELECT 
        P.Id AS PostId, 
        COUNT(V.Id) FILTER(WHERE V.VoteTypeId = 2) AS Upvotes, 
        COUNT(V.Id) FILTER(WHERE V.VoteTypeId = 3) AS Downvotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
UserPostStats AS (
    SELECT 
        U.UserId,
        COALESCE(SUM(PV.Upvotes), 0) AS TotalUpvotes,
        COALESCE(SUM(PV.Downvotes), 0) AS TotalDownvotes
    FROM UserReputation U
    LEFT JOIN PostVoteDetails PV ON U.UserId = PV.PostId
    GROUP BY U.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    PP.PostId,
    PP.Title,
    PP.Score,
    PP.ViewCount,
    PP.CommentCount,
    COALESCE(V.Upvotes, 0) AS PostUpvotes,
    COALESCE(V.Downvotes, 0) AS PostDownvotes,
    CASE 
        WHEN UR.TotalUpvotes > UR.TotalDownvotes THEN 'Positive Contributor'
        WHEN UR.TotalDownvotes > UR.TotalUpvotes THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS UserContributionType
FROM UserReputation U
JOIN PopularPosts PP ON PP.PopularityRank <= 10
LEFT JOIN PostVoteDetails V ON PP.PostId = V.PostId
LEFT JOIN UserPostStats UR ON U.UserId = UR.UserId
WHERE U.Reputation > 1000
ORDER BY PP.Score DESC, PP.ViewCount DESC;
