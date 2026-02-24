
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT
        UserId,
        DisplayName,
        Upvotes,
        Downvotes,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY Upvotes DESC, Downvotes ASC) AS UserRank
    FROM 
        UserActivity
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
FinalStats AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        ru.Upvotes,
        ru.Downvotes,
        ru.TotalPosts,
        ru.TotalComments,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ru.UserRank
    FROM 
        RankedUsers ru
    LEFT JOIN 
        UserBadges ub ON ru.UserId = ub.UserId
)
SELECT 
    fs.DisplayName,
    (fs.Upvotes - fs.Downvotes) AS NetUpvotes,
    fs.TotalPosts,
    fs.TotalComments,
    (fs.GoldBadges + fs.SilverBadges + fs.BronzeBadges) AS TotalBadges,
    fs.UserRank
FROM 
    FinalStats fs
WHERE 
    fs.TotalPosts > 10
ORDER BY 
    NetUpvotes DESC, 
    fs.TotalPosts DESC
LIMIT 10;
