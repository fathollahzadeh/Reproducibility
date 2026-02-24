
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        p.Score IS NOT NULL
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalBounties,
        ups.TotalPosts,
        ups.AvgPostScore,
        RANK() OVER (ORDER BY ups.TotalBounties DESC, ups.AvgPostScore DESC) AS UserRank
    FROM 
        UserPostStats ups
    WHERE 
        ups.TotalPosts > 0
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.TotalBounties,
    tp.TotalPosts,
    tp.AvgPostScore,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate
FROM 
    TopUsers tp
LEFT JOIN 
    RankedPosts rp ON tp.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    tp.UserRank <= 10
ORDER BY 
    tp.TotalBounties DESC, tp.AvgPostScore DESC;
