
WITH RECURSIVE RecursivePostHierarchy AS (
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.ParentId,
        p2.Title,
        rph.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy rph ON p2.ParentId = rph.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COALESCE(SUM(v.vote_count), 0) AS TotalVotes,
    MAX(p.CreationDate) AS LastPostDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed,
    CASE 
        WHEN COUNT(DISTINCT b.Id) > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1
                     WHEN VoteTypeId = 3 THEN -1
                     ELSE 0 END) AS vote_count
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
LEFT JOIN 
    (
        SELECT 
            p.Id,
            unnest(string_to_array(p.Tags, ',')) AS TagName
        FROM 
            Posts p
    ) t ON p.Id = t.Id
WHERE 
    u.Reputation > 1000  
GROUP BY 
    u.Id, 
    u.DisplayName, 
    u.Reputation
ORDER BY 
    TotalVotes DESC, 
    LastPostDate DESC
LIMIT 10;
