WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.AnswerCount, 0)) AS AvgAnswers
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
VoteSummary AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.AvgAnswers, 0) AS AvgAnswers,
    COALESCE(VS.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(VS.TotalDownvotes, 0) AS TotalDownvotes,
    CASE 
        WHEN COALESCE(UB.GoldBadges, 0) > 0 THEN 'Gold Badge Holder'
        WHEN COALESCE(UB.SilverBadges, 0) > 0 THEN 'Silver Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    VoteSummary VS ON U.Id = VS.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    TotalScore DESC, TotalViews DESC
FETCH FIRST 10 ROWS ONLY;