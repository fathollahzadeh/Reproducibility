WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostStatistics AS (
    SELECT 
        tp.Id,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        tp.OwnerDisplayName
    FROM 
        TopPosts tp
    LEFT JOIN 
        VoteSummary vs ON tp.Id = vs.PostId
)
SELECT 
    ps.Id,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.UpVotes,
    ps.DownVotes,
    (ps.UpVotes - ps.DownVotes) AS NetVotes,
    COUNT(c.Id) AS CommentCount
FROM 
    PostStatistics ps
LEFT JOIN 
    Comments c ON ps.Id = c.PostId
WHERE 
    ps.Score > 5
GROUP BY 
    ps.Id, ps.Title, ps.CreationDate, ps.Score, ps.ViewCount, ps.UpVotes, ps.DownVotes
ORDER BY 
    NetVotes DESC, ps.CreationDate DESC
LIMIT 10;