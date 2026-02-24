
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ScoreRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
),
PostSummaries AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Author,
        tp.CreationDate,
        tp.Score,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        (tp.UpVotes - tp.DownVotes) AS NetVotes,
        CASE 
            WHEN tp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM 
        TopPosts tp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Author,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.NetVotes,
    ps.CommentStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostSummaries ps
LEFT JOIN 
    Posts p ON p.Id = ps.PostId
LEFT JOIN 
    LATERAL UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS tag_name ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_name
GROUP BY 
    ps.PostId, ps.Title, ps.Author, ps.CreationDate, ps.Score, ps.CommentCount, ps.UpVotes, ps.DownVotes, ps.NetVotes, ps.CommentStatus
ORDER BY 
    ps.NetVotes DESC
LIMIT 10;
