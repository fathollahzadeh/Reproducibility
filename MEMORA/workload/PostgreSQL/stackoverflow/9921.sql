WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Owner,
        CreationDate,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Owner,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        vs.UpVotes,
        vs.DownVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        VoteStatistics vs ON tp.PostId = vs.PostId
)
SELECT 
    pd.Title,
    pd.Owner,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    COALESCE(pd.UpVotes, 0) AS UpVotes,
    COALESCE(pd.DownVotes, 0) AS DownVotes,
    pd.Score * 1.0 / NULLIF(pd.ViewCount, 0) AS EngagementRatio
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;