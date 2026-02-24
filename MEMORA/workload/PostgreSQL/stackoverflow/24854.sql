
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        MAX(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadge,
        MAX(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadge,
        MAX(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadge
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.ViewCount IS NOT NULL 
        AND p.CreationDate < TIMESTAMP '2024-10-01 12:34:56' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.GoldBadge,
        rp.SilverBadge,
        rp.BronzeBadge,
        CASE 
            WHEN rp.PostRank = 1 AND rp.Score >= 100 THEN 'Top Performing'
            ELSE 'Regular'
        END AS PerformanceCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score IS NOT NULL AND rp.Score > 0
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (6, 4) THEN 1 ELSE 0 END) AS TitleEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalPostData AS (
    SELECT 
        h.PostId,
        h.Title,
        h.Score,
        h.ViewCount,
        h.CommentCount,
        h.PerformanceCategory,
        p.EditCount,
        p.LastEditDate,
        p.TitleEdits,
        p.CloseVotes,
        CASE 
            WHEN p.CloseVotes > 3 THEN 'Highly Closed'
            ELSE 'Active'
        END AS ClosureStatus
    FROM 
        HighScorePosts h
    LEFT JOIN 
        PostHistoryInfo p ON h.PostId = p.PostId
    WHERE 
        h.GoldBadge = 1 OR h.SilverBadge = 1 OR h.BronzeBadge = 1
)
SELECT 
    f.*, 
    COALESCE(NULLIF(h.Title, ''), 'Untitled') AS SafeTitle,
    CASE 
        WHEN f.ClosureStatus = 'Highly Closed' THEN 'This post has been frequently closed; consider revising.'
        ELSE 'This post is currently active and well-received.'
    END AS StatusMessage
FROM 
    FinalPostData f
LEFT JOIN 
    Posts h ON f.PostId = h.Id
ORDER BY 
    f.Score DESC, 
    f.ViewCount DESC
LIMIT 100;
