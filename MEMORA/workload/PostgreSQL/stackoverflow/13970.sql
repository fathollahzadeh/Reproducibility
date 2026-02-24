
WITH UserPosts AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(Posts.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id,
        Users.DisplayName
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(P.PostCount, 0) AS PostCount,
    COALESCE(P.TotalScore, 0) AS TotalScore,
    COALESCE(P.TotalViews, 0) AS TotalViews,
    COALESCE(P.TotalComments, 0) AS TotalComments,
    COALESCE(P.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges
FROM 
    Users U
LEFT JOIN 
    UserPosts P ON U.Id = P.UserId
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId
ORDER BY 
    TotalScore DESC, 
    PostCount DESC
LIMIT 100;
