
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS total_posts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    up.DisplayName,
    COUNT(DISTINCT rp.Id) AS TotalQuestions,
    SUM(COALESCE(pvs.VoteScore, 0)) AS TotalVotes,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass IS NULL THEN 'No Badge'
        ELSE CASE 
            WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
            WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
            ELSE 'Bronze'
        END
    END AS HighestBadge
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    PostVoteStats pvs ON rp.Id = pvs.PostId
GROUP BY 
    up.Id, up.DisplayName, ub.BadgeCount, ub.HighestBadgeClass
HAVING 
    COUNT(DISTINCT rp.Id) > 5 
ORDER BY 
    TotalVotes DESC, TotalQuestions DESC;
