
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.PostTypeId, 
        p.AcceptedAnswerId, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.PostTypeId, 
        p.AcceptedAnswerId, 
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
), VoteCounts AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
), ClosedPostCount AS (
    SELECT 
        p.OwnerUserId AS UserId, 
        COUNT(*) AS ClosedPosts
    FROM 
        Posts p
    WHERE 
        p.Id IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId IN (10, 12)) 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    COALESCE(vc.UpVotes, 0) AS UpVotes,
    COALESCE(vc.DownVotes, 0) AS DownVotes,
    ur.Reputation,
    COALESCE(cpc.ClosedPosts, 0) AS ClosedPosts,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'Top Contributor'
        WHEN ur.Reputation > 500 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    PostHierarchy ph
LEFT JOIN 
    VoteCounts vc ON ph.PostId = vc.PostId
LEFT JOIN 
    Users u ON ph.PostId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    ClosedPostCount cpc ON u.Id = cpc.UserId
WHERE 
    ph.Level = (SELECT MAX(Level) FROM PostHierarchy) 
    AND ur.Reputation IS NOT NULL
ORDER BY 
    COALESCE(cpc.ClosedPosts, 0) DESC, 
    COALESCE(vc.UpVotes, 0) DESC, 
    ur.Reputation DESC;
