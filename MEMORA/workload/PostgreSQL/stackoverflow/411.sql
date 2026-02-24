WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - P.CreationDate))) AS AvgPostAgeSeconds
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RankedUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        P.TotalPosts,
        P.TotalQuestions,
        P.TotalAnswers,
        P.TotalScore,
        P.AvgPostAgeSeconds,
        RANK() OVER (ORDER BY P.TotalScore DESC) AS ScoreRank
    FROM UserBadgeStats U
    JOIN PostStats P ON U.UserId = P.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    COALESCE(U.GoldBadges, 0) AS GoldBadges,
    COALESCE(U.SilverBadges, 0) AS SilverBadges,
    COALESCE(U.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(P.TotalPosts, 0) AS TotalPosts,
    COALESCE(P.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(P.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(P.TotalScore, 0) AS TotalScore,
    ROUND(P.AvgPostAgeSeconds, 2) AS AvgPostAgeSeconds,
    U.ScoreRank,
    CASE 
        WHEN COALESCE(U.GoldBadges, 0) >= 1 THEN 'Gold Member'
        WHEN COALESCE(U.SilverBadges, 0) >= 1 THEN 'Silver Member'
        ELSE 'Regular Member' 
    END AS MembershipStatus
FROM RankedUsers U
LEFT JOIN PostStats P ON U.UserId = P.OwnerUserId
WHERE U.GoldBadges IS NOT NULL OR U.SilverBadges IS NOT NULL
ORDER BY U.ScoreRank, U.DisplayName;