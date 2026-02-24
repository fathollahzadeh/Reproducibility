WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END), 0) AS UpvotedPosts
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserBadgeStats AS (
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
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS TotalComments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
CombinedStats AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.ReputationRank,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.UpvotedPosts, 0) AS UpvotedPosts,
        COALESCE(UBS.TotalBadges, 0) AS TotalBadges,
        COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges
    FROM 
        UserReputation UR
    LEFT JOIN 
        PostStats PS ON UR.UserId = PS.OwnerUserId
    LEFT JOIN 
        UserBadgeStats UBS ON UR.UserId = UBS.UserId
)
SELECT 
    CS.UserId,
    CS.DisplayName,
    CS.Reputation,
    CS.ReputationRank,
    CS.TotalPosts,
    CS.TotalQuestions,
    CS.TotalAnswers,
    CS.UpvotedPosts,
    CS.TotalBadges,
    CS.GoldBadges,
    CS.SilverBadges,
    CS.BronzeBadges,
    COALESCE(PC.TotalComments, 0) AS TotalComments
FROM 
    CombinedStats CS
LEFT JOIN 
    PostComments PC ON CS.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PC.PostId LIMIT 1)
WHERE 
    CS.Reputation > 500
ORDER BY 
    CS.TotalPosts DESC, CS.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
