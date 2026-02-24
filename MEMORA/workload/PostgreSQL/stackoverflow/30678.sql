
WITH RecursivePostCTE AS (
    SELECT 
        Id,
        Title,
        PostTypeId,
        ParentId,
        OwnerUserId,
        CreationDate,
        Score,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS UserPostRank
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        p.Id
),
PostScores AS (
    SELECT
        p.Id,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    ub.DisplayName AS Owner,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(ps.TotalBounty, 0) AS TotalBounty,
    COALESCE(ps.Upvotes, 0) AS Upvotes,
    COALESCE(ps.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN rp.Score + COALESCE(ps.Upvotes, 0) - COALESCE(ps.Downvotes, 0) < 0 THEN 0 
        ELSE rp.Score + COALESCE(ps.Upvotes, 0) - COALESCE(ps.Downvotes, 0) 
    END AS NetScore,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM PostHistory ph 
            WHERE ph.PostId = rp.Id AND ph.PostHistoryTypeId = 10
        ) THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RecursivePostCTE rp
JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    RecentPostComments pc ON rp.Id = pc.PostId
LEFT JOIN 
    PostScores ps ON rp.Id = ps.Id
WHERE 
    rp.UserPostRank <= 10 
ORDER BY 
    NetScore DESC;
