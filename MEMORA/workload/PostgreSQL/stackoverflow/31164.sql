
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation + COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS ReputationScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
DetailedPostInfo AS (
    SELECT 
        ph.PostId,
        ph.Title,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.PostId) AS TotalComments,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ph.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = ph.PostId AND v.VoteTypeId = 3) AS DownVoteCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT ReputationScore FROM UserReputation WHERE UserId = p.OwnerUserId) AS OwnerReputationScore
    FROM 
        PostHierarchy ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    d.Title,
    d.TotalComments,
    d.UpVoteCount,
    d.DownVoteCount,
    d.OwnerDisplayName,
    d.OwnerReputationScore,
    CASE 
        WHEN d.OwnerReputationScore > 1000 THEN 'Experienced User'
        WHEN d.OwnerReputationScore BETWEEN 500 AND 1000 THEN 'Moderately Experienced User'
        ELSE 'New User'
    END AS UserExperience
FROM 
    DetailedPostInfo d
WHERE 
    d.UpVoteCount - d.DownVoteCount > 0 
ORDER BY 
    d.UpVoteCount DESC, 
    d.TotalComments DESC
LIMIT 10;
