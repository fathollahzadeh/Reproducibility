
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostEngagement AS (
    SELECT 
        P.OwnerUserId,
        COUNT(C.Id) AS TotalComments,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalBounty,
    UA.TotalVotes,
    COALESCE(BC.TotalBadges, 0) AS TotalBadges,
    COALESCE(BC.GoldBadges, 0) AS GoldBadges,
    COALESCE(BC.SilverBadges, 0) AS SilverBadges,
    COALESCE(BC.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PE.TotalComments, 0) AS TotalComments,
    COALESCE(PE.AcceptedAnswers, 0) AS AcceptedAnswers
FROM 
    UserActivity UA
LEFT JOIN 
    BadgeCounts BC ON UA.UserId = BC.UserId
LEFT JOIN 
    PostEngagement PE ON UA.UserId = PE.OwnerUserId
ORDER BY 
    UA.TotalPosts DESC, UA.TotalVotes DESC;
