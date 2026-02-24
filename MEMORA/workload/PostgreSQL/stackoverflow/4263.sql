
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(cnt.CommentsCount, 0) AS CommentsCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentsCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) AS cnt ON p.Id = cnt.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.CommentsCount,
    tc.DisplayName AS TopContributor,
    tc.TotalScore AS ContributorScore
FROM 
    RankedPosts r
LEFT JOIN 
    TopContributors tc ON r.OwnerUserId = tc.UserId
WHERE 
    r.RankByScore <= 5 
ORDER BY 
    r.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
