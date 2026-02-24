
WITH LatestPostEdits AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
),
MaxVotes AS (
    SELECT 
        PostId, 
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class IN (1, 2, 3)  
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        COALESCE(MAX(pt.Name), 'Unknown Type') AS PostTypeName,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.PostTypeName,
    le.UserDisplayName,
    le.EditDate,
    COALESCE(mv.VoteCount, 0) AS TotalVotes,
    ub.BadgeCount,
    CASE 
        WHEN lb.BadgeCount >= 1 THEN 'Top Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    RecentPosts rp
LEFT JOIN 
    LatestPostEdits le ON rp.Id = le.PostId AND le.rn = 1
LEFT JOIN 
    MaxVotes mv ON rp.Id = mv.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    UserBadges lb ON ub.BadgeCount = (SELECT MAX(BadgeCount) FROM UserBadges)
WHERE 
    rp.CreationDate IS NOT NULL 
ORDER BY 
    rp.CreationDate DESC;
