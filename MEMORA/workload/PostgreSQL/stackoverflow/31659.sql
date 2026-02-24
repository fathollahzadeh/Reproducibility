
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate 
    FROM 
        Users 
    WHERE 
        Reputation > 100 
    UNION ALL 
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate 
    FROM 
        Users u
    INNER JOIN 
        UserReputation ur ON u.Id = ur.Id 
    WHERE 
        u.Reputation < ur.Reputation
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS IsAccepted,
        COUNT(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS PostRank 
    FROM 
        PostSummary ps
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT ur.Id) AS ReputationEligibleUsers,
    COUNT(DISTINCT rp.PostId) AS RankedPostsCount,
    SUM(rp.Score) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON ur.Id = u.Id
LEFT JOIN 
    RankedPosts rp ON rp.IsAccepted = 1 AND rp.CreationDate < u.CreationDate
WHERE 
    u.Reputation IS NOT NULL AND 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 5
ORDER BY 
    TotalScore DESC;
