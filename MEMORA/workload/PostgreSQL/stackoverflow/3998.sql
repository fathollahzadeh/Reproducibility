
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounties,
        COALESCE(NULLIF(SUM(v.BountyAmount), 0), 0) AS AdjustedBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
FilteredUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.TotalBounties,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity ua
    WHERE 
        ua.Reputation > 1000 AND 
        ua.PostCount > 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)
SELECT 
    fu.UserId,
    fu.DisplayName,
    fu.Reputation,
    fu.PostCount,
    fu.QuestionCount,
    fu.AnswerCount,
    fu.TotalBounties,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    COALESCE(rp.RecentRank, 0) AS IsRecentPost
FROM 
    FilteredUsers fu
LEFT JOIN 
    RecentPosts rp ON fu.UserId = rp.OwnerUserId
WHERE 
    (fu.QuestionCount > 5 OR fu.AnswerCount > 10)
ORDER BY 
    fu.Reputation DESC, 
    fu.UserId
LIMIT 50;
