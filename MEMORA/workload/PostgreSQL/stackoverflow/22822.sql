
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetScore,  
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT l.RelatedPostId) AS LinkedPosts
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks l ON p.Id = l.PostId
    GROUP BY 
        p.Id
),
ImportantPosts AS (
    SELECT 
        ps.PostId,
        ps.NetScore,
        ps.CommentCount,
        ROW_NUMBER() OVER (ORDER BY ps.NetScore DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostScores ps
    WHERE 
        ps.NetScore > 0
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        COUNT(DISTINCT p.Id) AS ActivePostCount
    FROM 
        UserReputation ur
    JOIN 
        Posts p ON ur.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        ur.UserId, ur.Reputation, ur.BadgeCount, ur.GoldBadges, ur.SilverBadges, ur.BronzeBadges
)
SELECT 
    au.UserId,
    au.Reputation,
    au.BadgeCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    COUNT(ip.PostId) AS ImportantPostsCount,
    AVG(ip.NetScore) AS AverageNetScore,
    SUM(CASE WHEN ip.Rank <= 10 THEN 1 ELSE 0 END) AS TopTenPostsCount
FROM 
    ActiveUsers au
LEFT JOIN 
    ImportantPosts ip ON au.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ip.PostId)
GROUP BY 
    au.UserId, au.Reputation, au.BadgeCount, au.GoldBadges, au.SilverBadges, au.BronzeBadges
HAVING 
    SUM(CASE WHEN ip.Rank <= 10 THEN 1 ELSE 0 END) > 0
ORDER BY 
    au.Reputation DESC, ImportantPostsCount DESC;
