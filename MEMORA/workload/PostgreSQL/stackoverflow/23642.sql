WITH RecursivePostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptedAnswerScore,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1  
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), VoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    u.DisplayName AS Owner,
    u.Reputation,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ps.Upvotes,
    ps.Downvotes,
    ps.TotalVotes,
    COALESCE(pp.AcceptedAnswerScore, 0) AS AcceptedAnswerScore,
    pp.CommentCount,
    CASE 
        WHEN pp.UserPostRank = 1 AND ub.GoldBadges > 0 THEN 'Top Contributor with Gold Badge'
        WHEN pp.UserPostRank <= 5 THEN 'Active Contributor'
        ELSE 'Regular User'
    END AS UserStatus,
    CASE 
        WHEN pp.CommentCount > 50 THEN 'High Engagement'
        WHEN pp.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' THEN 'Old Post'
        ELSE 'Recent Activity'
    END AS PostEngagement
FROM 
    RecursivePostData pp
JOIN 
    Users u ON pp.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    VoteStats ps ON pp.PostId = ps.PostId
WHERE 
    pp.Title ILIKE '%SQL%'  
ORDER BY 
    pp.CreationDate DESC
LIMIT 100;