
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS PopularityRank
    FROM Posts P
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount 
               FROM Comments 
               GROUP BY PostId) C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1
    AND P.AcceptedAnswerId IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MIN(PH.CreationDate) AS FirstClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
),
CombinedStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.Score,
        PS.ViewCount,
        PS.CommentCount,
        COALESCE(CP.CloseCount, 0) AS ClosedCount,
        CP.FirstClosedDate,
        US.PostCount AS UserPostCount
    FROM PopularPosts PS
    LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
    LEFT JOIN UserStats US ON PS.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = US.UserId)
)
SELECT 
    CS.PostId,
    CS.Title,
    CS.Score,
    CS.ViewCount,
    CS.CommentCount,
    CS.ClosedCount,
    CS.FirstClosedDate,
    CS.UserPostCount,
    CASE 
        WHEN CS.ClosedCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM CombinedStats CS
WHERE CS.CommentCount > 10 OR CS.Score > 50
ORDER BY CS.Score DESC, CS.CommentCount DESC
LIMIT 50;
