WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(GREATEST(p.ViewCount, p.Score), 0) AS EngagementScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(u.UpVotes) AS TotalUpVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id
), 
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.PostsCount,
        ue.TotalBounties,
        ue.TotalUpVotes,
        ue.AvgReputation,
        RANK() OVER (ORDER BY ue.TotalUpVotes DESC) AS UserRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.PostsCount > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ue.UserId,
    ue.PostsCount,
    ue.TotalBounties,
    ue.TotalUpVotes
FROM 
    RankedPosts rp
INNER JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    TopEngagedUsers ue ON u.Id = ue.UserId
WHERE 
    rp.Rank <= 10 AND 
    (ue.TotalUpVotes IS NULL OR ue.TotalBounties > 0)
ORDER BY 
    rp.EngagementScore DESC, ue.TotalUpVotes DESC
LIMIT 50;