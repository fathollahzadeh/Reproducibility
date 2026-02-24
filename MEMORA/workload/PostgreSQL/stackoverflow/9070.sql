
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(MAX(b.Name), 'No Badge') AS HighestBadge,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserLatestPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        ViewCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        HighestBadge
    FROM 
        PostStats
    WHERE 
        UserLatestPostRank = 1  
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.CreationDate,
    pp.ViewCount,
    pp.CommentCount,
    pp.UpVoteCount,
    pp.DownVoteCount,
    pp.HighestBadge,
    COUNT(DISTINCT ph.UserId) AS EditHistoryCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    TopPosts pp
LEFT JOIN 
    PostHistory ph ON ph.PostId = pp.PostId
GROUP BY 
    pp.PostId, pp.Title, pp.Score, pp.CreationDate, pp.ViewCount, pp.CommentCount,
    pp.UpVoteCount, pp.DownVoteCount, pp.HighestBadge
ORDER BY 
    pp.Score DESC, pp.CreationDate ASC
LIMIT 10;
