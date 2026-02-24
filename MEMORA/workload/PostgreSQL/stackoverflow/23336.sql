
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        CASE 
            WHEN U.Reputation IS NULL THEN 'No Reputation'
            WHEN U.Reputation < 100 THEN 'New Contributor'
            WHEN U.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate Member'
            ELSE 'Established Expert'
        END AS ReputationLevel
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        UR.DisplayName AS Username,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalPosts, 0) DESC) AS Rank,
        UR.UserId
    FROM UserReputation UR
    LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
),
PostsWithBadges AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerName,
        B.Name AS BadgeName,
        CASE 
            WHEN B.Class = 1 THEN 'Gold'
            WHEN B.Class = 2 THEN 'Silver'
            WHEN B.Class = 3 THEN 'Bronze'
            ELSE 'No Badge'
        END AS BadgeClass
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE B.Date >= CURRENT_DATE - INTERVAL '1 year'
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        PH.Text,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11, 12, 13) 
)
SELECT 
    UPS.Username,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalViews,
    UPS.AverageScore,
    PH.PostId,
    PH.Comment,
    PH.Text AS HistoryText,
    PH.CreationDate AS HistoryDate,
    PWB.BadgeName,
    PWB.BadgeClass,
    CASE 
        WHEN mur.ReputationLevel = 'Established Expert' AND UPS.TotalPosts > 50 THEN 'Veteran Contributor'
        ELSE 'Contribution In Progress'
    END AS ContributorStatus
FROM UserPostStats UPS
JOIN UserReputation mur ON UPS.UserId = mur.UserId
LEFT JOIN RecentPostHistory PH ON UPS.TotalPosts = PH.PostId
LEFT JOIN PostsWithBadges PWB ON PWB.PostId = UPS.TotalPosts
WHERE 
    UPS.TotalViews > 10
    AND (PH.HistoryRank IS NULL OR PH.HistoryRank <= 3)
ORDER BY UPS.Rank, UPS.TotalViews DESC
LIMIT 100;
