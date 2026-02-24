
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(v.VoteCount, 0) AS TotalVotes,
        COUNT(a.Id) AS AnswerVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, v.VoteCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Rank,
        rp.TotalVotes,
        rp.AnswerVotes,
        CASE WHEN rp.Score > 100 THEN 'High' 
             WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium' 
             ELSE 'Low' END AS ScoreCategory
    FROM RankedPosts rp
    WHERE rp.Rank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.ScoreCategory,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(b.BadgeCount, 0) AS UserBadges
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
WHERE 
    u.Reputation > 500 AND (fp.ScoreCategory = 'High' OR fp.TotalVotes > 10)
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;
