
WITH UserScoreStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        PH.CreationDate AS CloseDate,
        PH.Comment AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 
        AND P.PostTypeId = 1 
),
RankedClosedPosts AS (
    SELECT 
        CP.*,
        COUNT(*) OVER (PARTITION BY CP.OwnerUserId) AS ClosedPostCount
    FROM 
        ClosedPosts CP
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.Upvotes,
    U.Downvotes,
    RC.CloseDate,
    RC.CloseReason,
    RC.ClosedPostCount
FROM 
    UserScoreStats U
LEFT JOIN 
    RankedClosedPosts RC ON U.UserId = RC.OwnerUserId
WHERE 
    (U.Reputation > 100 OR U.Upvotes > 10) 
    AND (RC.ClosedPostCount IS NULL OR RC.ClosedPostCount < 3)
ORDER BY 
    U.Reputation DESC,
    U.Upvotes DESC;
