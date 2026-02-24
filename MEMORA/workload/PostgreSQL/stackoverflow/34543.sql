WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.Score,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.PostTypeId, p.AcceptedAnswerId, p.Score
),
FilteredPosts AS (
    SELECT 
        r.PostId,
        r.OwnerUserId,
        r.Title,
        r.CreationDate,
        r.PostTypeId,
        r.AcceptedAnswerId,
        r.Score,
        r.TotalBounty,
        r.CommentCount
    FROM 
        RecursivePostCTE r
    WHERE 
        r.PostRank <= 5  
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN f.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN f.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COUNT(DISTINCT f.PostId) AS TotalPosts,
        COUNT(DISTINCT f.CommentCount) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts f ON u.Id = f.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalPosts,
    us.TotalComments,
    CASE 
        WHEN us.Reputation >= 1000 THEN 'High Reputation'
        WHEN us.Reputation >= 500 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = us.UserId) AS TotalUserPosts,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = us.UserId AND v.VoteTypeId = 2) AS TotalUpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = us.UserId AND v.VoteTypeId = 3) AS TotalDownVotes
FROM 
    UserStats us
WHERE 
    us.Reputation > 0
ORDER BY 
    us.Reputation DESC, us.TotalPosts DESC;