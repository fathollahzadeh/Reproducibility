
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    INNER JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(DISTINCT p.Id) > 5
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        tu.DisplayName AS TopUser,
        CASE 
            WHEN rp.ScoreRank = 1 THEN 'Top Score'
            ELSE 'Regular Score'
        END AS ScoreCategory
    FROM RankedPosts rp
    LEFT JOIN TopUsers tu ON EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.OwnerUserId = tu.UserId AND p.Id = rp.PostId
    )
    WHERE rp.Score > 10
)

SELECT 
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.CreationDate,
    pp.TopUser,
    pp.ScoreCategory,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM PopularPosts pp
ORDER BY pp.Score DESC, pp.ViewCount ASC
LIMIT 50;
