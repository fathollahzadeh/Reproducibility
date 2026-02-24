
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(DISTINCT v.UserId) AS UpVoteCount 
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(b.Class) AS TotalBadges, 
        SUM(p.Score) AS TotalScore 
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
    ORDER BY TotalScore DESC 
    LIMIT 10
),
PostDetails AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.CommentCount, 
        rp.UpVoteCount, 
        tu.DisplayName AS TopUser, 
        tu.TotalBadges 
    FROM RecentPosts rp
    JOIN TopUsers tu ON rp.UpVoteCount > 0
    ORDER BY rp.Score DESC, rp.ViewCount DESC
)
SELECT 
    pd.PostId, 
    pd.Title, 
    pd.CreationDate, 
    pd.Score, 
    pd.ViewCount, 
    pd.CommentCount, 
    pd.UpVoteCount, 
    pd.TopUser, 
    pd.TotalBadges 
FROM PostDetails pd
WHERE pd.UpVoteCount >= 5
ORDER BY pd.CreationDate DESC;
