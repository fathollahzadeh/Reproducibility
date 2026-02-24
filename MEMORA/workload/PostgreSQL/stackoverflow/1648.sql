WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.LastActivityDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    COALESCE(UPC.QuestionCount, 0) AS TotalQuestions,
    COALESCE(UPC.AnswerCount, 0) AS TotalAnswers,
    COALESCE(Badge.BadgeCount, 0) AS TotalBadges,
    COALESCE(Badge.GoldCount, 0) AS TotalGoldBadges,
    COALESCE(Badge.SilverCount, 0) AS TotalSilverBadges,
    COALESCE(Badge.BronzeCount, 0) AS TotalBronzeBadges,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate
FROM 
    Users U
LEFT JOIN 
    UserPostCounts UPC ON U.Id = UPC.UserId
LEFT JOIN 
    BadgeSummary Badge ON U.Id = Badge.UserId
LEFT JOIN 
    RecentActivity R ON U.Id = R.UserId AND R.RecentPostRank = 1
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC
LIMIT 10;