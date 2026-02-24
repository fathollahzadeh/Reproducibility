WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score IS NOT NULL AND p.Score > 0
), 
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    GROUP BY 
        b.UserId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(pv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pv.DownVotes, 0) AS TotalDownVotes,
    COALESCE(bc.BadgeCount, 0) AS GoldBadges,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot Post'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Trending Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        ELSE 'Scored'
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.Id = pv.PostId
LEFT JOIN 
    Users u ON rp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    BadgesCount bc ON u.Id = bc.UserId
WHERE 
    rp.rn = 1  
    AND (rp.ViewCount > 50 OR bc.BadgeCount > 2)
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;