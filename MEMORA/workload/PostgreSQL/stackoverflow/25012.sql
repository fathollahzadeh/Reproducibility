WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        u.DisplayName AS AuthorDisplayName,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'  
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagCount,
        rp.AuthorDisplayName,
        rp.Reputation,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.vote_count), 0) AS TotalVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS vote_count 
        FROM Votes 
        GROUP BY PostId
    ) v ON v.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.TagCount, rp.AuthorDisplayName, rp.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.TagCount,
    ps.AuthorDisplayName,
    ps.Reputation,
    ps.CommentCount,
    ps.TotalVotes,
    CASE 
        WHEN ps.Score >= 10 THEN 'High Score'
        WHEN ps.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN ps.TagCount > 5 THEN 'Diverse Tags'
        ELSE 'Limited Tags'
    END AS TagDiversity
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 50;