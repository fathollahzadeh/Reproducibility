WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
TopRanked AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 OR rp.ViewCount >= 100
),
PostDetails AS (
    SELECT 
        tr.PostId,
        tr.Title,
        tr.Score,
        tr.ViewCount,
        tr.CommentCount,
        tr.UpVotes,
        tr.DownVotes,
        COALESCE(b.Name, 'N/A') AS BadgeName,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        TopRanked tr
    LEFT JOIN 
        Badges b ON tr.PostId = b.UserId
    LEFT JOIN 
        PostHistory ph ON tr.PostId = ph.PostId 
        AND ph.PostHistoryTypeId IN (4, 5)
    GROUP BY 
        tr.PostId, tr.Title, tr.Score, tr.ViewCount, tr.CommentCount, tr.UpVotes, tr.DownVotes, b.Name
)
SELECT 
    pd.*,
    (pd.UpVotes - pd.DownVotes) AS VoteNet,
    CASE 
        WHEN pd.CommentCount IS NULL THEN 'No Comments'
        WHEN pd.CommentCount = 0 THEN 'No Comments'
        ELSE CAST(pd.CommentCount AS VARCHAR)
    END AS CommentStatus
FROM 
    PostDetails pd
WHERE 
    pd.Score > 0
ORDER BY 
    VoteNet DESC,
    LastEditDate DESC
LIMIT 20;