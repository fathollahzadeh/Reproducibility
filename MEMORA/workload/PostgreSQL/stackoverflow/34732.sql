
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Id AS OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Id, u.DisplayName
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryCreationDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '7 days'
),
AggregatedPostHistory AS (
    SELECT 
        p.PostId,
        COUNT(ph.PostHistoryTypeId) AS HistoryCount,
        MAX(ph.HistoryCreationDate) AS LastHistoryDate
    FROM 
        RecentPosts p
    LEFT JOIN 
        PostHistoryInfo ph ON p.PostId = ph.PostId
    GROUP BY 
        p.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerUserId,
    rp.OwnerDisplayName,
    rp.CommentCount,
    COALESCE(aph.HistoryCount, 0) AS RecentHistoryCount,
    aph.LastHistoryDate,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post'
    END AS PostRank,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownvoteCount
FROM 
    RecentPosts rp
LEFT JOIN 
    AggregatedPostHistory aph ON rp.PostId = aph.PostId
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC
LIMIT 50;
