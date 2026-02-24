WITH RECURSIVE UserPostCTE AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostCTE
    WHERE 
        TotalPosts > 0
), 
PostScoreCTE AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId, 
        p.Score,
        CASE 
            WHEN p.Score > 10 THEN 'High'
            WHEN p.Score BETWEEN 1 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory,
        COALESCE(
            (SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes v WHERE v.PostId = p.Id), 
            0
        ) AS Upvotes
    FROM 
        Posts p
), 
TopPosts AS (
    SELECT 
        p.PostId,
        p.OwnerUserId,
        p.ScoreCategory,
        p.Upvotes,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Upvotes DESC, p.Score DESC) as Rank
    FROM 
        PostScoreCTE p
)
SELECT 
    u.DisplayName, 
    u.TotalPosts, 
    u.QuestionCount, 
    u.AnswerCount,
    tp.PostId, 
    tp.ScoreCategory, 
    tp.Upvotes
FROM 
    MostActiveUsers u
LEFT JOIN 
    TopPosts tp ON u.UserId = tp.OwnerUserId AND tp.Rank = 1
WHERE 
    u.PostRank <= 10
ORDER BY 
    u.PostRank;