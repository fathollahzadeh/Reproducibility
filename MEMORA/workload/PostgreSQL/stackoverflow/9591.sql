
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
BestPosts AS (
    SELECT 
        r.PostId, 
        r.Title, 
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.CommentCount,
        r.UpVotes,
        r.DownVotes,
        ROW_NUMBER() OVER (ORDER BY r.Score DESC, r.ViewCount DESC) AS OverallRank 
    FROM 
        RankedPosts r 
    WHERE 
        r.Rank <= 5 
)
SELECT 
    bp.Title,
    bp.CreationDate,
    bp.Score,
    bp.ViewCount,
    bp.CommentCount,
    bp.UpVotes,
    bp.DownVotes,
    u.DisplayName AS OwnerDisplayName
FROM 
    BestPosts bp
JOIN 
    Users u ON bp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    bp.OverallRank <= 10 
ORDER BY 
    bp.OverallRank;
