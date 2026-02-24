
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(PC.CommentCount, 0)) AS TotalComments,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CommentCount
         FROM Comments 
         GROUP BY PostId) PC ON P.Id = PC.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.Body,
        P.PostTypeId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY PH.UserId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 5
)
SELECT 
    AU.UserRank,
    AU.DisplayName,
    AU.Reputation,
    COALESCE(RPH.Title, 'No Recent Activity') AS RecentPostTitle,
    COALESCE(RPH.Body, 'No Body Available') AS RecentPostBody,
    COUNT(DISTINCT PHT.PostId) AS HistoricalPostCount,
    SUM(CASE WHEN PHT.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenedCount,
    AVG(COALESCE(V.BountyAmount, 0)) AS AvgBounty
FROM 
    ActiveUsers AU
LEFT JOIN 
    RecentPostHistory RPH ON AU.UserId = RPH.UserId AND RPH.rn = 1
LEFT JOIN 
    PostHistory PHT ON PHT.UserId = AU.UserId
LEFT JOIN 
    Votes V ON V.PostId = PHT.PostId
GROUP BY 
    AU.UserRank, AU.DisplayName, AU.Reputation, RPH.Title, RPH.Body
HAVING 
    COUNT(PHT.PostId) > 2
ORDER BY 
    AU.UserRank, AU.Reputation DESC
LIMIT 10;
