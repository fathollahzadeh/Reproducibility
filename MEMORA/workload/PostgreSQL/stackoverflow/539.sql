WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.Score > 0 
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END), 0) AS Favorites
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ua.Upvotes,
    ua.Downvotes,
    ua.Favorites,
    COALESCE(phe.EditCount, 0) AS EditCount,
    phe.LastEditDate,
    CASE 
        WHEN rp.Score >= 100 THEN 'Hot'
        WHEN rp.Score >= 50 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON rp.Id = ua.UserId
LEFT JOIN 
    PostHistorySummary phe ON rp.Id = phe.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.CreationDate DESC;