
WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')))
),
UserBadges AS (
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
        U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PT.Name AS PostType,
        P.CreationDate,
        P.ViewCount,
        COALESCE(CAST(P.AnswerCount AS VARCHAR), '0') AS AnswerCount,
        COALESCE(CAST(P.CommentCount AS VARCHAR), '0') AS CommentCount,
        COALESCE(CAST(P.FavoriteCount AS VARCHAR), '0') AS FavoriteCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.LastActivityDate >= DATE '2024-10-01' - INTERVAL '30 days'
)
SELECT 
    P.Title,
    P.PostType,
    P.ViewCount,
    US.DisplayName AS TopUser,
    US.BadgeCount,
    TS.Tag,
    TS.PostCount,
    TS.TotalViews,
    TS.AverageScore
FROM 
    PostAnalytics P
JOIN 
    UserBadges US ON P.PostId = US.UserId 
JOIN 
    TagStats TS ON P.Title LIKE '%' || TS.Tag || '%' 
WHERE 
    US.BadgeCount > 0
ORDER BY 
    P.ViewCount DESC, TS.TotalViews DESC
LIMIT 10;
