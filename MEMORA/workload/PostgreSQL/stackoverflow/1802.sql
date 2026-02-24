
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5 
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
)
SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass IS NULL THEN 'No Badge'
        ELSE CASE WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
                  WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
                  WHEN ub.HighestBadgeClass = 3 THEN 'Bronze'
                  ELSE 'Unknown' END
    END AS HighestBadge,
    CASE 
        WHEN fp.ViewCount > 100 THEN 'Popular' 
        WHEN fp.ViewCount BETWEEN 50 AND 100 THEN 'Moderate' 
        ELSE 'Less Viewed' 
    END AS ViewPopularity
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON p.Id = fp.PostId
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    fp.UpVotes > fp.DownVotes OR fp.Score > 10
ORDER BY 
    fp.CreationDate DESC;
