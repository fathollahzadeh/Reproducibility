
WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS Comments,
        COALESCE(a.AnswerCount, 0) AS Answers,
        p.Score,
        p.Score + COALESCE(c.CommentCount, 0) + COALESCE(a.AnswerCount, 0) AS InteractionScore,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId AS PostId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.TotalBounty,
    us.Upvotes,
    us.Downvotes,
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Comments,
    pi.Answers,
    pi.Score,
    pi.InteractionScore,
    ROW_NUMBER() OVER (PARTITION BY us.UserId ORDER BY pi.InteractionScore DESC) AS Rank
FROM 
    UserScore us
LEFT JOIN 
    PostInteraction pi ON us.UserId = pi.OwnerUserId
WHERE 
    us.PostCount > 0
    AND pi.InteractionScore IS NOT NULL
ORDER BY 
    us.TotalBounty DESC, us.Upvotes DESC, us.Downvotes ASC;
