
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.OwnerUserId, 
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(cc.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) cc ON p.Id = cc.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(u.UpVotes) AS UpVoteCount,
        SUM(u.DownVotes) AS DownVoteCount,
        AVG(COALESCE(rp.CommentCount, 0)) AS AvgCommentsPerPost
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    us.UpVoteCount,
    us.DownVoteCount,
    us.AvgCommentsPerPost,
    (CASE 
        WHEN us.TotalScore > 100 THEN 'High Scorer'
        WHEN us.TotalScore BETWEEN 50 AND 100 THEN 'Medium Scorer'
        ELSE 'Low Scorer'
    END) AS ScoreCategory,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = us.UserId 
       AND b.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = us.UserId 
       AND b.Class = 2) AS SilverBadges,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId = us.UserId 
       AND b.Class = 3) AS BronzeBadges
FROM 
    UserStats us
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.TotalScore DESC, us.DisplayName ASC
LIMIT 100 OFFSET 0;
