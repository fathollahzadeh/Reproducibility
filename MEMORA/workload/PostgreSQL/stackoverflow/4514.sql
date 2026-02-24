
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY SUM(u.UpVotes) - SUM(u.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(b.Id) > 3 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.ScoreRank,
    tu.DisplayName AS TopUser,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.ViewCount > 100 AND rp.Score > 10 
WHERE 
    rp.ScoreRank = 1 
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
