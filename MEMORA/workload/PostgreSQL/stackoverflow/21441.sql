
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY p.Id, u.DisplayName, p.Title, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.Upvotes,
        pd.Downvotes,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS Rank
    FROM PostDetails pd
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Rank
    FROM RankedPosts rp
    WHERE rp.Rank <= 10
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount
    FROM PostHistory ph
    GROUP BY ph.PostId
),
PostWithHistory AS (
    SELECT 
        tp.*,
        COALESCE(phc.HistoryCount, 0) AS HistoryCount
    FROM TopPosts tp
    LEFT JOIN PostHistoryCounts phc ON tp.PostId = phc.PostId
)
SELECT 
    pwh.Title,
    pwh.OwnerDisplayName,
    pwh.Rank,
    pwh.HistoryCount,
    CASE 
        WHEN pwh.HistoryCount > 5 THEN 'Frequent Updates'
        WHEN pwh.HistoryCount = 0 THEN 'No History'
        ELSE 'Moderate Updates'
    END AS UpdateFrequency,
    CONCAT('Post ', pwh.Title, ' (Rank: ', pwh.Rank, ') - Updated ', pwh.HistoryCount, ' times') AS Summary
FROM PostWithHistory pwh
WHERE pwh.OwnerDisplayName IS NOT NULL
ORDER BY pwh.Rank;
