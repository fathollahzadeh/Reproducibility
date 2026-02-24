WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
RecentComments AS (
    SELECT 
        c.PostId, 
        c.Text AS CommentText, 
        c.CreationDate AS CommentDate, 
        u.DisplayName AS CommentedBy
    FROM 
        Comments c
    JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        c.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days'
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate AS PostCreationDate, 
    rp.Score AS PostScore, 
    rp.ViewCount AS PostViewCount, 
    rp.AnswerCount AS PostAnswerCount, 
    rp.CommentCount AS PostCommentCount, 
    tu.DisplayName AS TopUser,
    tc.CommentText, 
    tc.CommentDate, 
    tc.CommentedBy
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.Rank <= 3
LEFT JOIN 
    RecentComments tc ON rp.PostId = tc.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;