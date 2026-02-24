WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
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
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.PostId) AS ClosedPostCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.UserId
),
TopUsers AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.TotalBadges,
        PS.TotalPosts,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.AvgScore,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPosts
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostStatistics PS ON UB.UserId = PS.OwnerUserId
    LEFT JOIN 
        ClosedPosts CP ON UB.UserId = CP.UserId
    WHERE 
        (UB.TotalBadges > 0 OR PS.TotalPosts IS NOT NULL) 
)
SELECT 
    TU.DisplayName,
    TU.TotalBadges,
    TU.TotalPosts,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.AvgScore,
    TU.ClosedPosts,
    CASE 
        WHEN TU.ClosedPosts > 10 THEN 'Frequent Closer'
        ELSE 'Occasional Closer'
    END AS ClosingHabit,
    RANK() OVER (ORDER BY TU.AvgScore DESC) AS ScoreRank
FROM 
    TopUsers TU
ORDER BY 
    ScoreRank, TU.DisplayName
LIMIT 20;