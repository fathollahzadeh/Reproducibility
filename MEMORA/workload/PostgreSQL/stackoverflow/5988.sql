WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score, p.CreationDate
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(rp.Score) AS AverageScore,
        COUNT(rp.PostId) AS TotalPosts
    FROM 
        Users u
    JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        rp.Rank <= 3
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.AverageScore,
    tu.TotalPosts,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    TopUsers tu
LEFT JOIN Badges b ON tu.UserId = b.UserId AND b.Class = 1 /* Gold Badge */
ORDER BY 
    tu.AverageScore DESC,
    tu.TotalPosts DESC;