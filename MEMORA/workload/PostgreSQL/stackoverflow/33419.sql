WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(MAX(b.Class), 0) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
QualifiedUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        SUM(rp.TotalBounty) AS TotalBountiesEarned,
        COUNT(distinct rp.PostId) AS BountyPostsCount
    FROM 
        UserReputation ur
    JOIN 
        RecentPosts rp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        ur.UserId, ur.DisplayName, ur.Reputation
)
SELECT 
    q.DisplayName,
    q.Reputation,
    q.TotalBountiesEarned,
    CASE 
        WHEN q.Reputation > 1000 THEN 'High'
        WHEN q.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory,
    ph.Comment AS LastComment,
    ph.CreationDate AS LastCommentDate
FROM 
    QualifiedUsers q
LEFT JOIN 
    RecursivePostHistory ph ON q.UserId = ph.UserId AND ph.rn = 1
ORDER BY 
    q.TotalBountiesEarned DESC,
    q.Reputation DESC
LIMIT 10;