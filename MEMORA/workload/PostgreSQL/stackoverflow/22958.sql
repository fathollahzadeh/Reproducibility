WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS TotalBadges, 
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
        U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE 
            WHEN P.PostTypeId = 1 THEN P.AnswerCount 
            ELSE 0 
        END) AS TotalAnswersForQuestions,
        SUM(CASE 
            WHEN P.PostTypeId = 1 AND P.ClosedDate IS NOT NULL THEN 1 
            ELSE 0 
        END) AS ClosedQuestions
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(UBC.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.TotalAnswersForQuestions, 0) AS TotalAnswersForQuestions,
        COALESCE(PS.ClosedQuestions, 0) AS ClosedQuestions
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
),
UserEngagement AS (
    SELECT 
        UA.UserId,
        UA.Reputation,
        UA.TotalBadges,
        UA.TotalPosts,
        UA.AvgScore,
        UA.TotalViews,
        UA.TotalAnswersForQuestions,
        UA.ClosedQuestions,
        RANK() OVER (ORDER BY UA.Reputation DESC, UA.TotalPosts DESC) AS ReputationRank
    FROM 
        UserActivity UA
)
SELECT 
    U.UserId, 
    U.Reputation, 
    U.TotalBadges, 
    U.TotalPosts,
    U.AvgScore, 
    U.TotalViews,
    U.TotalAnswersForQuestions,
    U.ClosedQuestions,
    CASE 
        WHEN U.Reputation < 1000 THEN 'Newcomer'
        WHEN U.Reputation BETWEEN 1000 AND 5000 THEN 'Contributor'
        WHEN U.Reputation > 5000 THEN 'Expert'
        ELSE 'Undefined' 
    END AS UserTier,
    CASE 
        WHEN U.ClosedQuestions > 0 THEN 'Has Closed Questions'
        ELSE 'No Closed Questions' 
    END AS ClosureStatus
FROM 
    UserEngagement U
WHERE 
    U.TotalPosts > 10
ORDER BY 
    U.ReputationRank;
