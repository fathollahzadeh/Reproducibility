WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS Questions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS Answers,
        COALESCE(SUM(CASE WHEN P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 ELSE 0 END), 0) AS RecentPosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.UserId, PH.PostId, PH.PostHistoryTypeId
),
CombinedStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(RP.TotalPosts, 0) AS TotalPosts,
        COALESCE(RP.Questions, 0) AS Questions,
        COALESCE(RP.Answers, 0) AS Answers,
        COALESCE(RP.RecentPosts, 0) AS RecentPosts,
        COALESCE(PH.EditCount, 0) AS EditCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeStats UB ON U.Id = UB.UserId
    LEFT JOIN 
        RecentPostStats RP ON U.Id = RP.OwnerUserId
    LEFT JOIN 
        PostHistoryDetails PH ON U.Id = PH.UserId
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.Reputation,
    C.TotalBadges,
    C.TotalPosts,
    C.Questions,
    C.Answers,
    C.RecentPosts,
    CASE 
        WHEN C.EditCount > 10 THEN 'Frequent Edits'
        WHEN C.EditCount BETWEEN 5 AND 10 THEN 'Moderate Edits'
        WHEN C.EditCount < 5 THEN 'Infrequent Edits' 
        ELSE 'No Edits' 
    END AS EditFrequency,
    CASE 
        WHEN C.Reputation < 100 THEN 'New User'
        WHEN C.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate User'
        ELSE 'Experienced User'
    END AS UserLevel
FROM 
    CombinedStats C
WHERE 
    C.TotalPosts > 0
ORDER BY 
    C.Reputation DESC, C.TotalBadges DESC;