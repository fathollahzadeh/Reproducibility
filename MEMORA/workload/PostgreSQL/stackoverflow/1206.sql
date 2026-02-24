WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentComments AS (
    SELECT 
        c.PostId,
        c.UserDisplayName,
        c.Text,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
)
SELECT 
    rp.Title,
    rp.CreationDate,
    us.Reputation,
    us.BadgeCount,
    us.TotalBounty,
    rc.UserDisplayName AS LastCommentUser,
    rc.Text AS LastCommentText
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.Id IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
LEFT JOIN 
    RecentComments rc ON rp.Id = rc.PostId AND rc.CommentRank = 1
WHERE 
    rp.rn <= 3 
ORDER BY 
    us.Reputation DESC, 
    rp.Score DESC
LIMIT 100;