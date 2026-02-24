
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PostAnalysis AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Owner,
        CommentCount,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC) AS VoteRank
    FROM 
        RankedPosts
)
SELECT 
    pa.Title,
    pa.Owner,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.NetVotes,
    pht.Name AS PostHistoryType,
    pt.Name AS PostType
FROM 
    PostAnalysis pa
JOIN 
    Posts post ON pa.PostId = post.Id
JOIN 
    PostHistory ph ON ph.PostId = post.Id
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    PostTypes pt ON post.PostTypeId = pt.Id
WHERE 
    pa.VoteRank <= 10
ORDER BY 
    pa.NetVotes DESC, pa.Score DESC;
