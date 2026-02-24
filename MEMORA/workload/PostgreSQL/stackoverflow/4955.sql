
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName, p.PostTypeId
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        DENSE_RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentAction
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (DATE '2024-10-01' - INTERVAL '7 days')
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    (SELECT 
        STRING_AGG(DISTINCT pt.Name, ', ') 
     FROM 
        PostHistoryTypes pt 
     JOIN 
        RecentPostHistory rph ON rph.PostHistoryTypeId = pt.Id 
     WHERE 
        rph.PostId = rp.PostId AND rph.RecentAction = 1) AS RecentAction,
    (SELECT 
        COUNT(v.Id) 
     FROM 
        Votes v 
     WHERE 
        v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    CASE 
        WHEN rp.ViewCount > 1000 THEN 'Popular'
        WHEN rp.ViewCount > 100 THEN 'Moderate'
        ELSE 'Less Popular' 
    END AS Popularity
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.ViewCount DESC;
