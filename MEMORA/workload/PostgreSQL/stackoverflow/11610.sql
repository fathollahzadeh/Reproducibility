WITH UserPosts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(c.CommentCount, 0)) AS CommentCount,
        SUM(COALESCE(v.VoteCount, 0)) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),

BenchmarkResults AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        up.PostCount,
        up.CommentCount,
        up.VoteCount
    FROM 
        Users u
    JOIN 
        UserPosts up ON u.Id = up.UserId
)
SELECT 
    Reputation,
    COUNT(UserId) AS UserCount,
    SUM(PostCount) AS TotalPosts,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes
FROM 
    BenchmarkResults
GROUP BY 
    Reputation
ORDER BY 
    Reputation DESC;