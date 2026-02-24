
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(uc.UserCount, 0) AS UniqueCommentCount,
        COALESCE(uc.UserNames, 'None') AS CommentUserNames,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(DISTINCT UserId) AS UserCount,
            STRING_AGG(DISTINCT UserDisplayName, ', ') AS UserNames
        FROM 
            Comments
        GROUP BY 
            PostId
    ) uc ON p.Id = uc.PostId
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS ViewRank
    FROM 
        PostStats ps
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    p.Title AS PostTitle,
    p.ViewCount,
    p.UniqueCommentCount,
    p.CommentUserNames,
    CASE 
        WHEN p.Rank = 1 THEN 'Top Post'
        WHEN p.Rank <= 10 THEN 'Trending Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    uvs.TotalUpVotes,
    uvs.TotalDownVotes
FROM 
    UserVoteStats uvs
JOIN 
    RankedPosts p ON uvs.UserId = p.PostId
WHERE 
    (uvs.TotalUpVotes + uvs.TotalDownVotes > 0)
    AND p.ViewCount > 50
ORDER BY 
    p.ViewCount DESC, 
    uvs.TotalUpVotes DESC
LIMIT 100;
