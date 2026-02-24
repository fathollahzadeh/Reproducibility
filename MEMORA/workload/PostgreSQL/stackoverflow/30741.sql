WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
), 
TopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
    WHERE
        CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstEditDate,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(PH.Id) AS EditCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName AS Author,
    U.Reputation,
    UBS.BadgeName,
    R.Score AS RecentPostScore,
    R.CommentCount AS RecentPostComments,
    PHS.FirstEditDate,
    PHS.LastEditDate,
    PHS.EditCount,
    PHS.CloseCount,
    UPosts.PostsCount,
    UPosts.TotalScore,
    UPosts.AvgScore,
    CASE 
        WHEN U.Reputation >= 1000 THEN 'High Reputation'
        WHEN U.Reputation >= 500 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    TopUsers U
LEFT JOIN 
    UserBadges UBS ON U.Id = UBS.UserId AND UBS.BadgeRank = 1
LEFT JOIN 
    RecentPosts R ON U.Id = R.OwnerUserId
LEFT JOIN 
    UserPostStats UPosts ON U.Id = UPosts.UserId
LEFT JOIN 
    PostHistorySummary PHS ON R.PostId = PHS.PostId
WHERE 
    U.Reputation > 200
ORDER BY 
    U.Reputation DESC, R.Score DESC;