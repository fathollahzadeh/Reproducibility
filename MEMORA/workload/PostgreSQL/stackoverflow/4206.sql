
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.VoteAmount, 0)) AS TotalVotes,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS EngagementRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS VoteAmount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
PostClosure AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(PH.Id) AS CloseCount,
        ARRAY_AGG(DISTINCT CT.Name) AS CloseReasons
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN CloseReasonTypes CT ON CAST(PH.Comment AS integer) = CT.Id
    WHERE P.ClosedDate IS NOT NULL
    GROUP BY P.Id, P.Title
),
PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) AS PopularityRank
    FROM Posts P
    WHERE P.Score > 50
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.TotalVotes,
    U.TotalViews,
    COALESCE(PC.CloseCount, 0) AS PostCloseCount,
    COALESCE(PC.CloseReasons, ARRAY[]::varchar[]) AS ClosureReasons,
    PP.PopularityRank
FROM UserEngagement U
LEFT JOIN PostClosure PC ON PC.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = U.UserId
)
LEFT JOIN PopularPosts PP ON PP.Id IN (
    SELECT Id FROM Posts WHERE OwnerUserId = U.UserId
)
WHERE U.EngagementRank <= 10
ORDER BY U.TotalVotes DESC, U.TotalViews DESC;
