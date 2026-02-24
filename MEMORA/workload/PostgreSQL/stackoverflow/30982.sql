
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount,
        MAX(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS IsDeleted
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        (p.Score > 10 OR p.ViewCount > 100) 
),
PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseReopenCount,
        MAX(rp.IsDeleted) AS IsDeleted
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.OwnerDisplayName, rp.Score, rp.ViewCount, rp.Rank, rp.CommentCount, rp.UpVoteCount, rp.DownVoteCount
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.OwnerDisplayName,
    pa.Score,
    pa.ViewCount,
    pa.Rank,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.CloseReopenCount,
    CASE 
        WHEN pa.IsDeleted = 1 THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostActivity pa
WHERE 
    pa.Rank <= 10 
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC;
