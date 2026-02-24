
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        CloseVotes,
        Upvotes,
        Downvotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.Questions,
    t.Answers,
    t.CloseVotes,
    t.Upvotes,
    t.Downvotes,
    ROUND((CAST(t.Upvotes AS DECIMAL) / NULLIF(t.TotalPosts, 0)) * 100, 2) AS UpvotePercentage,
    ROUND((CAST(t.Downvotes AS DECIMAL) / NULLIF(t.TotalPosts, 0)) * 100, 2) AS DownvotePercentage
FROM 
    TopUsers t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank;
