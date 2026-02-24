WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerDisplayName, 
        rp.Score, 
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
),
VoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FinalStats AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.CreationDate, 
        tp.OwnerDisplayName, 
        tp.Score, 
        tp.ViewCount, 
        vs.UpVotes, 
        vs.DownVotes, 
        vs.TotalVotes
    FROM 
        TopPosts tp
    JOIN 
        VoteStatistics vs ON tp.PostId = vs.PostId
)
SELECT 
    fs.PostId, 
    fs.Title, 
    fs.CreationDate, 
    fs.OwnerDisplayName, 
    fs.Score, 
    fs.ViewCount, 
    fs.UpVotes, 
    fs.DownVotes, 
    fs.TotalVotes
FROM 
    FinalStats fs
ORDER BY 
    fs.Score DESC, 
    fs.ViewCount DESC;