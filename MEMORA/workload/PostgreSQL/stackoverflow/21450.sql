
WITH UserRanks AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE 
            WHEN B.Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN B.Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN B.Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostsStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RecentActivity AS (
    SELECT 
        P.OwnerUserId,
        MAX(P.CreationDate) AS LastActivityDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UR.ReputationRank, 0) AS ReputationRank,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(RA.LastActivityDate, DATE '1900-01-01') AS LastActivityDate,
        COALESCE(RA.TotalComments, 0) AS TotalComments,
        CASE 
            WHEN COALESCE(UR.BadgeCount, 0) = 0 THEN 'Unbadged User'
            WHEN COALESCE(UR.GoldBadges, 0) > 0 THEN 'Gold Badge Holder'
            WHEN COALESCE(UR.SilverBadges, 0) > 0 THEN 'Silver Badge Holder'
            ELSE 'Bronze Badge Holder'
        END AS BadgeCategory
    FROM 
        Users U
    LEFT JOIN 
        UserRanks UR ON U.Id = UR.UserId
    LEFT JOIN 
        PostsStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        RecentActivity RA ON U.Id = RA.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    ReputationRank,
    TotalPosts,
    Questions,
    Answers,
    TotalScore,
    LastActivityDate,
    TotalComments,
    BadgeCategory
FROM 
    UserPerformance
WHERE 
    (TotalPosts > 0 OR TotalComments > 0) 
    AND (ReputationRank < 100 OR BadgeCategory = 'Gold Badge Holder')
ORDER BY 
    CASE 
        WHEN TotalScore = 0 THEN NULL 
        ELSE TotalScore 
    END DESC,
    DisplayName ASC
LIMIT 50;
