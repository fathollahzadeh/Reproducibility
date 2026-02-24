
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    WHERE 
        rp.ScoreRank <= 10
),
PostStatistics AS (
    SELECT 
        t.Title,
        t.ViewCount,
        t.OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) AS GoldBadges,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class > 1) AS SilverBronzeBadges
    FROM 
        TopPosts t
    LEFT JOIN 
        Users u ON t.OwnerDisplayName = u.DisplayName
)
SELECT 
    p.Title,
    p.ViewCount,
    p.OwnerDisplayName,
    p.UpVotes,
    p.DownVotes,
    p.GoldBadges,
    p.SilverBronzeBadges,
    (CASE 
        WHEN p.UpVotes > p.DownVotes THEN 'Popular'
        WHEN p.UpVotes < p.DownVotes THEN 'Unpopular'
        ELSE 'Neutral'
    END) AS Popularity,
    (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) AS AvgQuestionScore
FROM 
    PostStatistics p
WHERE 
    p.ViewCount > 100
ORDER BY 
    p.ViewCount DESC
LIMIT 20;
