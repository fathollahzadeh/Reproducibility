
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3 
),
PostDetails AS (
    SELECT 
        tr.Id,
        tr.Title,
        tr.CreationDate,
        tr.ViewCount,
        tr.Score,
        tr.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        TopRankedPosts tr
    LEFT JOIN 
        Comments c ON tr.Id = c.PostId
    LEFT JOIN 
        Votes v ON tr.Id = v.PostId
    GROUP BY 
        tr.Id, tr.Title, tr.CreationDate, tr.ViewCount, tr.Score, tr.OwnerDisplayName
)
SELECT 
    pd.OwnerDisplayName,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
