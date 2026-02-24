WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.UpVotes,
        ue.DownVotes,
        ROW_NUMBER() OVER (ORDER BY (ue.UpVotes - ue.DownVotes) DESC) AS UserRank
    FROM UserEngagement ue
    WHERE ue.UpVotes - ue.DownVotes > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.RankByScore,
    tu.DisplayName AS TopUser,
    tu.UpVotes,
    tu.DownVotes
FROM RankedPosts rp
LEFT JOIN TopUsers tu ON rp.RankByScore = 1  
WHERE rp.RankByScore <= 5  
ORDER BY rp.PostId, tu.UpVotes DESC;