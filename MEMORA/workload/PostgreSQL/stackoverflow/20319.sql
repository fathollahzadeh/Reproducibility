WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(p.OwnerDisplayName, ''), 'Anonymous') AS DisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.DisplayName,
    ua.UpVotes,
    ua.DownVotes,
    ua.CommentCount,
    COALESCE(phc.EditCount, 0) AS TotalEdits,
    CASE 
        WHEN ua.GoldBadges > 0 THEN 'Gold' 
        WHEN ua.SilverBadges > 0 THEN 'Silver' 
        WHEN ua.BronzeBadges > 0 THEN 'Bronze' 
        ELSE 'No Badges' 
    END AS BadgeStatus,
    CASE 
        WHEN rp.ViewCount > 100 THEN 'Highly Viewed'
        WHEN rp.ViewCount BETWEEN 50 AND 100 THEN 'Moderately Viewed'
        ELSE 'Less Viewed'
    END AS ViewStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON rp.PostId = ua.UserId
LEFT JOIN 
    PostHistoryCounts phc ON rp.PostId = phc.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.CreationDate DESC,
    rp.Score DESC
LIMIT 10
OFFSET 5;