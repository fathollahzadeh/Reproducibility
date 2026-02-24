WITH RankedUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        Row_Number() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
    WHERE 
        Reputation > 1000
),
LatestPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
      AND p.Score > 0
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    lp.Title,
    lp.CreationDate,
    pv.VoteCount,
    pv.UpVotes,
    pv.DownVotes,
    CASE 
        WHEN pv.UpVotes IS NULL THEN 'No Votes'
        WHEN pv.UpVotes > pv.DownVotes THEN 'Positive Impact'
        ELSE 'Negative Impact'
    END AS VoteImpact,
    ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
FROM 
    RankedUsers u
JOIN 
    LatestPosts lp ON u.Id = lp.OwnerUserId
LEFT JOIN 
    PostVotes pv ON lp.PostId = pv.PostId
WHERE 
    lp.PostRank = 1
ORDER BY 
    u.Reputation DESC, 
    lp.CreationDate DESC
LIMIT 10
OFFSET 0;