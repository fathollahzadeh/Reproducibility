WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND p.ViewCount > 100
        AND p.PostTypeId IN (1, 2)  
),
PostStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    GROUP BY 
        p.PostId, p.Title, p.ViewCount
)
SELECT 
    s.PostId,
    s.Title,
    s.ViewCount,
    s.UpVotes,
    s.DownVotes,
    s.CommentCount,
    CASE WHEN rp.Rank <= 5 THEN 'Top Post' ELSE 'Regular Post' END AS PostRank
FROM 
    PostStats s
JOIN 
    RankedPosts rp ON s.PostId = rp.PostId
ORDER BY 
    s.UpVotes DESC, s.DownVotes ASC, s.ViewCount DESC;