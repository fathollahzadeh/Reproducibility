WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.RankByScore,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 3
        AND rp.CommentCount > 0
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        PHT.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    COALESCE(SUM(CASE WHEN phd.HistoryType = 'Post Closed' THEN 1 ELSE 0 END), 0) AS ClosedCount,
    ARRAY_AGG(DISTINCT phd.UserDisplayName) AS Editors,
    COUNT(DISTINCT phd.PostId) AS HistoryCount,
    CASE 
        WHEN COUNT(DISTINCT phd.PostId) > 0 THEN 'Has History'
        ELSE 'No History'
    END AS HistoryStatus,
    TRIM(BOTH ' ' FROM STRING_AGG(DISTINCT phd.Comment, ', ')) AS RecentComments
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryDetails phd ON fp.PostId = phd.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Score
ORDER BY 
    fp.Score DESC, ClosedCount ASC;