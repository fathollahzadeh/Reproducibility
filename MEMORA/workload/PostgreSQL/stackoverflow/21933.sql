WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
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
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
ClosedPostStats AS (
    SELECT 
        PH.UserId AS CloserUserId,
        COUNT(PH.PostId) AS ClosedPostCount,
        MIN(PH.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
),
FinalStats AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.QuestionCount, 0) AS TotalQuestions,
        COALESCE(PS.AnswerCount, 0) AS TotalAnswers,
        COALESCE(PS.AvgScore, 0) AS AveragePostScore,
        COALESCE(CS.ClosedPostCount, 0) AS TotalClosedPosts,
        COALESCE(CS.FirstCloseDate, '1970-01-01') AS FirstClosePostDate,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostStatistics PS ON UB.UserId = PS.OwnerUserId
    LEFT JOIN 
        ClosedPostStats CS ON UB.UserId = CS.CloserUserId
)
SELECT 
    FS.DisplayName,
    FS.TotalPosts,
    FS.TotalQuestions,
    FS.TotalAnswers,
    FS.AveragePostScore,
    FS.TotalClosedPosts,
    FS.FirstClosePostDate,
    CASE 
        WHEN FS.GoldBadges > 0 THEN 'Gold'
        WHEN FS.SilverBadges > 0 THEN 'Silver'
        WHEN FS.BronzeBadges > 0 THEN 'Bronze'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN FS.TotalPosts = 0 THEN 'Inactive'
        WHEN FS.TotalPosts <= 10 THEN 'New User'
        WHEN FS.TotalPosts <= 50 THEN 'Regular User'
        ELSE 'Veteran User'
    END AS UserRank
FROM 
    FinalStats FS
ORDER BY 
    FS.TotalPosts DESC,
    FS.AveragePostScore DESC;
