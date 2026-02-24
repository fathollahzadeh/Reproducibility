WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerUserId,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ARRAY_AGG(DISTINCT tag.TagName) AS Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        (SELECT 
            p.Id AS PostId, 
            unnest(string_to_array(p.Tags, '><')) AS TagName
          FROM 
            Posts p) tag ON tp.PostId = tag.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.CommentCount
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Close/Reopen Event'
            ELSE 'Other Event'
        END AS EventType,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS MostRecentEventDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)
SELECT 
    pd.Title, 
    pd.Score, 
    pd.CommentCount,
    pd.TotalBounty,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(rph.EventType) FILTER (WHERE rph.EventType = 'Close/Reopen Event') AS CloseReopenCount,
    CASE 
        WHEN MAX(rph.MostRecentEventDate) IS NULL THEN 'No recent activity'
        WHEN MAX(rph.MostRecentEventDate) < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days' THEN 'Inactive'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostDetails pd
LEFT JOIN 
    RecentPostHistory rph ON pd.PostId = rph.PostId
LEFT JOIN 
    LATERAL (SELECT unnest(pd.Tags) AS TagName) t ON TRUE
GROUP BY 
    pd.Title, pd.Score, pd.CommentCount, pd.TotalBounty
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC
LIMIT 50;