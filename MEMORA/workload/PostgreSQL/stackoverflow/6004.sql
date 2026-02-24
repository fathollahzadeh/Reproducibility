WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserVoteStats AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
TopUsers AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalScore,
        UPS.AcceptedAnswers,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges,
        UVS.TotalUpvotes,
        UVS.TotalDownvotes,
        RANK() OVER (ORDER BY UPS.TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        UserBadges UB ON UPS.UserId = UB.UserId
    LEFT JOIN 
        UserVoteStats UVS ON UPS.UserId = UVS.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.TotalScore,
    TU.AcceptedAnswers,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    TU.TotalUpvotes,
    TU.TotalDownvotes,
    TU.ScoreRank
FROM 
    TopUsers TU
WHERE 
    TU.ScoreRank <= 10
ORDER BY 
    TU.TotalScore DESC, TU.DisplayName;
