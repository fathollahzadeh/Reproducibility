WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(v.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(v.DownVotesCount, 0) AS DownVotesCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotesCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.UpVotesCount,
    r.DownVotesCount,
    r.CommentCount,
    CASE 
        WHEN r.Rank <= 10 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    RankedPosts r
WHERE 
    r.Rank <= 50
ORDER BY 
    r.ViewCount DESC;
