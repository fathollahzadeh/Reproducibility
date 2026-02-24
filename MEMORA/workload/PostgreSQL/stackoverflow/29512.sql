
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, u.DisplayName, p.Score, p.CreationDate
),

TopUsers AS (
    SELECT 
        r.OwnerUserId,
        r.OwnerDisplayName,
        SUM(r.UpVoteCount - r.DownVoteCount) AS NetVoteScore,
        COUNT(r.PostId) AS TotalQuestions,
        MIN(r.CreationDate) AS FirstPostDate
    FROM RankedPosts r
    WHERE r.PostRank <= 10  
    GROUP BY r.OwnerUserId, r.OwnerDisplayName
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    tu.TotalQuestions,
    tu.NetVoteScore,
    tu.FirstPostDate
FROM Users u
LEFT JOIN TopUsers tu ON u.Id = tu.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE u.Reputation > 1000  
ORDER BY tu.NetVoteScore DESC, tu.TotalQuestions DESC;
