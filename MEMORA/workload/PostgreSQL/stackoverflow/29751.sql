
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM UNNEST(string_to_array(p.Tags, '>'))) AS TagCount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(b.Class), 0) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.ViewCount > 1000
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
        p.CommentCount, p.Body, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score + (ps.UpVotes - ps.DownVotes) * 2 AS EngagementScore
    FROM 
        PostStatistics ps
    WHERE 
        ps.TagCount > 0
)
SELECT 
    tp.Title,
    tp.EngagementScore,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.TotalComments,
    ps.HighestBadgeClass
FROM 
    TopPosts tp
JOIN 
    PostStatistics ps ON tp.PostId = ps.PostId
ORDER BY 
    tp.EngagementScore DESC
LIMIT 10;
