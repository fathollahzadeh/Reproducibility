WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId IN (1, 2)) AS QuestionAnswerCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.QuestionAnswerCount, 0) AS QuestionAnswerCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(UBC.GoldCount, 0) AS GoldCount,
        COALESCE(UBC.SilverCount, 0) AS SilverCount,
        COALESCE(UBC.BronzeCount, 0) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UP.DisplayName,
    UP.BadgeCount,
    UP.TotalPosts,
    UP.QuestionAnswerCount,
    UP.TotalViews,
    UP.GoldCount,
    UP.SilverCount,
    UP.BronzeCount
FROM 
    UserPerformance UP
ORDER BY 
    UP.TotalViews DESC, UP.BadgeCount DESC;