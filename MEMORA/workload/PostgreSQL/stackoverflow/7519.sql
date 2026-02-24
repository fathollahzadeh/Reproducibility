WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS AuthorName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostSummary AS (
    SELECT 
        r.PostId, 
        r.Title, 
        r.Body, 
        r.CreationDate, 
        r.Score, 
        r.ViewCount,
        r.AuthorName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts r
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        Votes v ON r.PostId = v.PostId
    WHERE 
        r.TagRank <= 5
    GROUP BY 
        r.PostId, r.Title, r.Body, r.CreationDate, r.Score, r.ViewCount, r.AuthorName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AuthorName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    pt.Name AS PostType
FROM 
    PostSummary ps
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = ps.PostId)
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 50;