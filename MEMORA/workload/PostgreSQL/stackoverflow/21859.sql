WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),
TopPosts AS (
    SELECT 
        PostId, 
        Title,
        ViewCount,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN ph.CreationDate END) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
ComplexMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CommentCount,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        COALESCE(phd.EditCount, 0) AS EditCount,
        COALESCE(phd.LastEditDate, '1900-01-01') AS LastEditDate,
        CASE 
            WHEN pvc.UpVotes > pvc.DownVotes THEN 'More Upvotes' 
            WHEN pvc.DownVotes > pvc.UpVotes THEN 'More Downvotes'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteCounts pvc ON tp.PostId = pvc.PostId
    LEFT JOIN 
        PostHistoryDetails phd ON tp.PostId = phd.PostId
)
SELECT 
    cm.*,
    CASE 
        WHEN EditCount > 5 THEN 'Highly Edited'
        WHEN EditCount BETWEEN 2 AND 5 THEN 'Moderately Edited'
        ELSE 'Rarely Edited'
    END AS EditFrequency,
    CASE 
        WHEN VoteSentiment = 'More Upvotes' AND ViewCount > 100 THEN 'Trending'
        ELSE 'Stable'
    END AS TrendStatus
FROM 
    ComplexMetrics cm
WHERE 
    ViewCount IS NOT NULL
    AND (LastEditDate IS NULL OR LastEditDate < cast('2024-10-01' as date) - INTERVAL '30 days')
ORDER BY 
    ViewCount DESC, 
    EditCount DESC;