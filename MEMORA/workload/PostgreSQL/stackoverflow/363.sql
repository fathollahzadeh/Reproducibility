
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.Questions, 0) AS Questions,
        COALESCE(PS.Answers, 0) AS Answers,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        CASE 
            WHEN PS.TotalPosts IS NULL THEN 'No Posts'
            WHEN PS.TotalPosts > 100 THEN 'Top Contributor'
            ELSE 'Contributor'
        END AS ContributionLevel
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalBadges,
    US.TotalPosts,
    US.Questions,
    US.Answers,
    US.AvgScore,
    US.TotalViews,
    US.ContributionLevel,
    COALESCE((
        SELECT STRING_AGG(T.TagName, ', ') 
        FROM Tags T 
        JOIN Posts P ON T.ExcerptPostId = P.Id 
        WHERE P.OwnerUserId = US.UserId
    ), 'No Tags') AS AssociatedTags
FROM 
    UserSummary US
ORDER BY 
    US.Reputation DESC, 
    US.TotalPosts DESC
LIMIT 50;
