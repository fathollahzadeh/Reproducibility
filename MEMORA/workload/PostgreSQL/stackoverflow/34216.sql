
WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        RANK() OVER (ORDER BY SUM(COALESCE(P.ViewCount, 0)) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        RA.UserId,
        RA.DisplayName,
        RA.TotalViews,
        RA.TotalPosts,
        RANK() OVER (PARTITION BY RA.UserId ORDER BY P.LastActivityDate DESC) AS RecentRank
    FROM 
        RecursiveUserActivity RA
    JOIN 
        Posts P ON RA.UserId = P.OwnerUserId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PopularPosts AS (
    SELECT 
        Id,
        Title,
        Score,
        ViewCount,
        CreationDate,
        Tags,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS PopularityRank
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgesEarned
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
FinalResults AS (
    SELECT 
        RU.UserId,
        RU.DisplayName,
        RU.Reputation,
        COALESCE(UB.BadgesEarned, 'No badges') AS Badges,
        COALESCE(RA.TotalViews, 0) AS RecentViews,
        COALESCE(RA.TotalPosts, 0) AS RecentPosts,
        PP.Title AS PopularPostTitle,
        PP.Score AS PopularPostScore,
        PP.ViewCount AS PopularPostViewCount,
        PP.CreationDate AS PopularPostCreationDate
    FROM 
        RecursiveUserActivity RU
    LEFT JOIN 
        RecentActivity RA ON RU.UserId = RA.UserId
    LEFT JOIN 
        UserBadges UB ON RU.UserId = UB.UserId
    LEFT JOIN 
        PopularPosts PP ON PP.PopularityRank = 1
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    Badges,
    RecentViews,
    RecentPosts,
    PopularPostTitle,
    PopularPostScore,
    PopularPostViewCount,
    PopularPostCreationDate
FROM 
    FinalResults
WHERE 
    RecentPosts > 0
ORDER BY 
    Reputation DESC, RecentViews DESC;
