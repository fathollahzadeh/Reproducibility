WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.ViewCount) AS AvgViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND P.Id IN (
            SELECT PH.PostId 
            FROM PostHistory PH 
            WHERE PH.PostHistoryTypeId = 10
        )
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UM.DisplayName,
    UM.Reputation,
    PS.TotalPosts,
    PS.Questions,
    PS.Answers,
    PS.AvgViews,
    COALESCE(CP.ClosedCount, 0) AS ClosedPosts,
    UM.ReputationRank,
    CASE 
        WHEN UM.Reputation < 1000 THEN 'Novice'
        WHEN UM.Reputation BETWEEN 1000 AND 4999 THEN 'Intermediate'
        ELSE 'Expert'
    END AS UserLevel
FROM 
    UserMetrics UM
LEFT JOIN 
    PostSummary PS ON UM.UserId = PS.OwnerUserId
LEFT JOIN 
    ClosedPosts CP ON UM.UserId = CP.OwnerUserId
WHERE 
    (PS.TotalPosts IS NOT NULL AND PS.TotalPosts > 10) 
    OR UM.ReputationRank < 50
ORDER BY 
    UM.Reputation DESC, 
    PS.AvgViews DESC;
