
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostAnalysis AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViewCount,
        COUNT(DISTINCT PH.Id) AS EditCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedPosts
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        UP.PostCount,
        UP.TotalScore,
        UP.AverageViewCount,
        UP.EditCount,
        UP.ClosedPosts
    FROM 
        UserStats US
    LEFT JOIN 
        PostAnalysis UP ON US.UserId = UP.OwnerUserId
)
SELECT 
    DISTINCT US.DisplayName,
    US.Reputation,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.AverageViewCount,
    UPS.EditCount,
    UPS.ClosedPosts,
    CASE 
        WHEN UPS.Reputation >= 1000 THEN 'High'
        WHEN UPS.Reputation BETWEEN 500 AND 999 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory,
    CASE 
        WHEN UPS.PostCount IS NULL THEN 'No Posts'
        ELSE 'Has Posts'
    END AS PostStatus
FROM 
    UserStats US
LEFT JOIN 
    UserPostStats UPS ON US.UserId = UPS.UserId
ORDER BY 
    UPS.TotalScore DESC, US.Reputation DESC
LIMIT 100
OFFSET 0;
