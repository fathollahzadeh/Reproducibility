WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000 AND u.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '90 days'
    GROUP BY u.Id, u.DisplayName
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        au.UserId,
        au.DisplayName,
        (au.GoldBadges + au.SilverBadges + au.BronzeBadges) AS TotalBadges
    FROM RankedPosts rp
    CROSS JOIN ActiveUsers au
    WHERE rp.Rank <= 5 AND au.GoldBadges > 0
),
FilteredPosts AS (
    SELECT 
        DISTINCT cd.PostId,
        cd.Title,
        cd.CreationDate,
        cd.Score,
        cd.CommentCount,
        cd.UserId,
        cd.DisplayName,
        cd.TotalBadges
    FROM CombinedData cd
    WHERE cd.Score IS NOT NULL AND cd.TotalBadges > 1
    ORDER BY cd.Score DESC
)
SELECT 
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.DisplayName,
    fp.TotalBadges,
    CASE 
        WHEN fp.CommentCount > 10 THEN 'Highly Discussed'
        WHEN fp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionStatus,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2), 0) AS UpvoteCount,
    COALESCE((SELECT AVG(Score) FROM Posts p2 WHERE p2.Id = fp.PostId), 0) AS AverageScore
FROM FilteredPosts fp
WHERE fp.CreationDate < cast('2024-10-01' as date) - INTERVAL '7 days'
ORDER BY DiscussionStatus, fp.Score DESC;