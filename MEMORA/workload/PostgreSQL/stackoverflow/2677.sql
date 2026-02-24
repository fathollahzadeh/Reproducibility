WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(P.Score) FILTER (WHERE P.PostTypeId = 1) AS TotalQuestionScore,
        SUM(P.Score) FILTER (WHERE P.PostTypeId = 2) AS TotalAnswerScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN Comments C ON U.Id = C.UserId 
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
BadgesSummary AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalComments,
        UA.TotalBounty,
        UA.TotalQuestionScore,
        UA.TotalAnswerScore,
        COALESCE(BS.GoldBadges, 0) AS GoldBadges,
        COALESCE(BS.SilverBadges, 0) AS SilverBadges,
        COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
        RANK() OVER (ORDER BY UA.TotalPosts DESC, UA.TotalBounty DESC) AS Rank
    FROM UserActivity UA
    LEFT JOIN BadgesSummary BS ON UA.UserId = BS.UserId
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalPosts,
    T.TotalComments,
    T.TotalBounty,
    T.TotalQuestionScore,
    T.TotalAnswerScore,
    T.GoldBadges,
    T.SilverBadges,
    T.BronzeBadges,
    T.Rank
FROM TopUsers T
WHERE T.Rank <= 10
ORDER BY T.Rank;
