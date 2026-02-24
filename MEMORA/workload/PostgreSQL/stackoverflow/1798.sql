WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            ELSE 'Unanswered'
        END AS AnswerStatus
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostsCount,
        us.TotalBounty,
        RANK() OVER (ORDER BY us.PostsCount DESC, us.TotalBounty DESC) AS UserRank
    FROM UserStats us
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerStatus,
    tu.DisplayName,
    tu.UserRank
FROM RankedPosts rp
LEFT JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE rp.Rank <= 5 OR tu.UserRank IS NOT NULL
ORDER BY rp.Score DESC, tu.TotalBounty DESC;