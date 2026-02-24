WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 AND (rp.UpVoteCount - rp.DownVoteCount) > 10
),
PostDetails AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        (SELECT 
            COUNT(*) 
         FROM 
            Comments c 
         WHERE 
            c.PostId = fp.PostId) AS CommentCount,
        (SELECT 
            COUNT(*) 
         FROM 
            PostHistory ph 
         WHERE 
            ph.PostId = fp.PostId 
            AND ph.PostHistoryTypeId IN (10, 11, 12)) AS ClosureCount,
        fp.UpVoteCount,
        fp.DownVoteCount,
        fp.TotalBounty
    FROM 
        FilteredPosts fp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.ClosureCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.TotalBounty,
    COALESCE(pd.ClosureCount, 0) AS NonClosureCount
FROM 
    PostDetails pd
LEFT JOIN 
    Badges b ON pd.PostId = b.UserId
WHERE 
    pd.TotalBounty > 0 OR pd.ClosureCount IS NULL
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC
LIMIT 50
OFFSET 10;