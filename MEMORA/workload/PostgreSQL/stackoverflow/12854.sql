
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS TotalComments,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        p.OwnerUserId  -- Added to allow joining in final select
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AcceptedAnswerId, p.OwnerUserId
)

SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpvotes,
    us.TotalDownvotes,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.ViewCount AS PostViewCount,
    ps.Score AS PostScore,
    ps.TotalComments,
    ps.HasAcceptedAnswer
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
ORDER BY 
    us.TotalPosts DESC, ps.ViewCount DESC;
