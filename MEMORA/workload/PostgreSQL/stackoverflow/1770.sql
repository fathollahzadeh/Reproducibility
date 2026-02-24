
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        COALESCE(pts.Name, 'Unknown') AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pts ON p.PostTypeId = pts.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        PostRank
    FROM 
        PostDetails
    WHERE 
        Score > 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    CASE 
        WHEN pp.PostRank = 1 THEN 'Latest Post' 
        ELSE 'Previous Post' 
    END AS PostStatus
FROM 
    PopularPosts pp
LEFT JOIN 
    Comments c ON pp.PostId = c.PostId
LEFT JOIN 
    Votes v ON pp.PostId = v.PostId
GROUP BY 
    pp.PostId, pp.Title, pp.CreationDate, pp.Score, pp.ViewCount, pp.OwnerDisplayName, pp.PostRank
HAVING 
    MAX(pp.ViewCount) > 100
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
