
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(p.OwnerDisplayName, ''), 'Anonymous') AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2022-01-01'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, p.OwnerDisplayName, p.PostTypeId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastEdited,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Editors
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    rp.OwnerName,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEdited,
    phs.Editors,
    (rp.UpVoteCount - rp.DownVoteCount) AS NetVotes,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Post'
        WHEN rp.Rank <= 10 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank ASC;
