
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(COALESCE(v.BountyAmount, 0)) DESC) AS BountyRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, PostCount, CommentCount, TotalBounty
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
    ORDER BY 
        Reputation DESC
    LIMIT 10
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v2.VoteTypeId = 9 THEN v2.BountyAmount END), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v2 ON p.Id = v2.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
HighlightedPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.Score,
        pa.TotalComments,
        pa.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY pa.Score DESC, pa.TotalComments DESC) AS ActivityRank
    FROM 
        PostActivity pa
    WHERE 
        pa.CreationDate > CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    hp.Title,
    hp.CreationDate,
    hp.Score,
    hp.TotalComments,
    hp.TotalBounty 
FROM 
    TopUsers tu
FULL OUTER JOIN 
    HighlightedPosts hp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = hp.PostId)
WHERE 
    tu.Reputation IS NOT NULL OR hp.PostId IS NOT NULL
ORDER BY 
    tu.Reputation DESC, 
    hp.Score DESC;
