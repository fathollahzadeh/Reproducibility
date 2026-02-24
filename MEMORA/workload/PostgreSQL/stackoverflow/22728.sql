WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentTotal
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        CASE 
            WHEN rp.UserRank = 1 THEN 'Top Post' 
            ELSE 'Regular Post' 
        END AS PostType,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        RankedPosts rp 
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId AND b.Class = 1
    WHERE 
        rp.UserRank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    CASE 
        WHEN tp.Score > 100 THEN 'Highly Engaged'
        WHEN tp.Score > 50 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    (SELECT AVG(ViewCount) 
     FROM Posts 
     WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
       AND PostTypeId = 1) AS AvgRecentViews,
    tp.BadgeName,
    COUNT(DISTINCT ph.Id) AS HistoryCount,
    STRING_AGG(DISTINCT CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'Other' 
    END, ', ') AS ClosureStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.BadgeName
HAVING 
    COUNT(DISTINCT CASE 
          WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id 
          END) > 0
ORDER BY 
    tp.Score DESC;