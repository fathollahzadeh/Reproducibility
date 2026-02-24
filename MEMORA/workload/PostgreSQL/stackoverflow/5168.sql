WITH UserPostingStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS Wikis,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
UserVoteStats AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Votes V
    GROUP BY V.UserId
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.Questions,
    UPS.Answers,
    UPS.Wikis,
    UPS.TotalViews,
    UPS.TotalScore,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(UVS.Upvotes, 0) AS Upvotes,
    COALESCE(UVS.Downvotes, 0) AS Downvotes
FROM UserPostingStats UPS
LEFT JOIN UserBadges UB ON UPS.UserId = UB.UserId
LEFT JOIN UserVoteStats UVS ON UPS.UserId = UVS.UserId
ORDER BY UPS.TotalPosts DESC, UPS.TotalScore DESC
LIMIT 50;
