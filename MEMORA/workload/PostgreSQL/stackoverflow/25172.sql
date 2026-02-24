WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    LEFT JOIN 
        Comments c ON u.Id = c.UserId AND c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostsCount,
        CommentsCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        TotalViewCount,
        RANK() OVER (ORDER BY TotalViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY PostsCount DESC) AS PostRank,
        RANK() OVER (ORDER BY CommentsCount DESC) AS CommentRank,
        RANK() OVER (ORDER BY (GoldBadges + SilverBadges + BronzeBadges) DESC) AS BadgeRank
    FROM 
        UserActivity
),
UserScores AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        (ViewRank + PostRank + CommentRank + BadgeRank) AS TotalRankScore
    FROM 
        TopUsers
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalRankScore
FROM 
    UserScores
WHERE 
    TotalRankScore <= 10
ORDER BY 
    TotalRankScore ASC;