WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId 
    WHERE 
        v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.Id, u.DisplayName
),
PostRanks AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.RankScore,
        ru.DisplayName AS TopUser,
        ru.TotalBounties
    FROM 
        RecentPosts rp
    LEFT JOIN 
        TopUsers ru ON rp.OwnerUserId = ru.UserId
)
SELECT 
    pr.Title,
    pr.RankScore,
    COALESCE(pr.TopUser, 'No active user') AS ActiveBountyUser,
    COALESCE(pr.TotalBounties, 0) AS UserTotalBounties,
    CASE 
        WHEN pr.RankScore > 10 THEN 'High'
        WHEN pr.RankScore BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS RankCategory
FROM 
    PostRanks pr
WHERE 
    pr.RankScore IS NOT NULL
ORDER BY 
    pr.RankScore DESC
LIMIT 50;