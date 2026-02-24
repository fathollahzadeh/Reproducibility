
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS AuthorName,
        (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 3), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
RankedPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (PARTITION BY ps.AuthorName ORDER BY ps.Score DESC) AS Rank
    FROM 
        PostStats ps
)
SELECT 
    ua.DisplayName AS UserName,
    ua.PostCount,
    ua.TotalComments,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.DisplayName = rp.AuthorName AND rp.Rank = 1
WHERE 
    ua.PostCount > 0 AND 
    ua.TotalComments > 0
ORDER BY 
    ua.TotalUpvotes DESC, 
    ua.TotalDownvotes ASC;
