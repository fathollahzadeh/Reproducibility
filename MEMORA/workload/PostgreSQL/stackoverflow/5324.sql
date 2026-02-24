
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.PostTypeId, p.Score
), PopularPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        LastActivityDate,
        CommentCount,
        UpVotes,
        DownVotes,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.LastActivityDate,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    pt.Name AS PostTypeName
FROM 
    PopularPosts pp
JOIN 
    PostTypes pt ON pp.Rank = pt.Id
ORDER BY 
    pp.UpVotes DESC, pp.CreationDate DESC;
