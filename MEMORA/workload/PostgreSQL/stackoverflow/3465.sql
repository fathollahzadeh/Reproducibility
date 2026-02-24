
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(V.BountyAmount), 0) DESC) AS RankByBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostInfo AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        PH.UserId AS EditorId,
        PH.CreationDate AS EditDate,
        PH.Comment
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5)
    WHERE P.ViewCount > 1000 OR P.Score >= 10
),
RecentPosts AS (
    SELECT
        PostId,
        COUNT(*) AS EditCount,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS EditRank
    FROM PostHistory
    WHERE CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY PostId
),
CombinedInfo AS (
    SELECT 
        UI.DisplayName,
        PI.Title,
        PI.CreationDate,
        PI.Score,
        PI.ViewCount,
        COALESCE(RP.EditCount, 0) AS RecentEditCount
    FROM UserStats UI
    JOIN PostInfo PI ON UI.UserId = PI.OwnerUserId
    LEFT JOIN RecentPosts RP ON PI.PostId = RP.PostId
)
SELECT 
    CI.DisplayName,
    CI.Title,
    CI.CreationDate,
    CI.Score,
    CI.ViewCount,
    CI.RecentEditCount,
    CASE 
        WHEN CI.RecentEditCount > 5 THEN 'Highly Edited'
        WHEN CI.RecentEditCount BETWEEN 1 AND 5 THEN 'Moderately Edited'
        ELSE 'Rarely Edited'
    END AS EditFrequency,
    CASE 
        WHEN UI.RankByBounty <= 10 THEN 'Top Contributors'
        ELSE 'Regular Contributors'
    END AS ContributorType
FROM CombinedInfo CI
JOIN UserStats UI ON CI.DisplayName = UI.DisplayName
WHERE UI.TotalPosts > 10
ORDER BY CI.RecentEditCount DESC, CI.Score DESC;
