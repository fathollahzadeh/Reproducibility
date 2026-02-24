
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.ViewCount > 50 AND 
        (p.ClosedDate IS NULL OR p.PostTypeId = 1)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.ViewCount, p.AnswerCount, p.Score
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        RANK() OVER (ORDER BY us.TotalUpvotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS PostRank
    FROM 
        UserStats us
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.UpvoteRank,
    tu.PostRank,
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.ViewCount,
    pe.CommentCount,
    pe.AnswerCount,
    pe.Score,
    pe.LastActivityDate
FROM 
    TopUsers tu
JOIN 
    PostEngagement pe ON tu.UserId = pe.PostId
WHERE 
    tu.UpvoteRank <= 10 OR 
    tu.PostRank <= 10
ORDER BY 
    tu.Reputation DESC, 
    pe.LastActivityDate DESC;
