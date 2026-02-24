WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.ViewCount) AS AvgViews
    FROM
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        CASE 
            WHEN p.Score >= 10 THEN 'High'
            WHEN p.Score >= 5 THEN 'Medium'
            ELSE 'Low' 
        END AS ScoreCategory
    FROM 
        Posts p
),
TopPosts AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        ps.PostId,
        ps.ScoreRank,
        ps.ScoreCategory,
        COALESCE(pht.Comment, 'No comments') AS LastEditComment
    FROM 
        UserPosts up
    JOIN 
        PostScores ps ON up.UserId = ps.OwnerUserId
    LEFT JOIN 
        PostHistory pht ON ps.PostId = pht.PostId AND pht.PostHistoryTypeId IN (24, 12) 
    WHERE 
        ps.ScoreRank <= 3
)
SELECT 
    tp.UserId,
    tp.DisplayName,
    tp.PostId,
    tp.ScoreRank,
    tp.ScoreCategory,
    tp.LastEditComment,
    up.TotalPosts,
    up.Questions,
    up.Answers,
    up.AvgViews
FROM 
    TopPosts tp
JOIN 
    UserPosts up ON tp.UserId = up.UserId
ORDER BY 
    up.TotalPosts DESC, tp.ScoreRank ASC;